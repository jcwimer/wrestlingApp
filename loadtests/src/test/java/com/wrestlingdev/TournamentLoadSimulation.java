package com.wrestlingdev;

import io.gatling.javaapi.core.ChainBuilder;
import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;
import io.gatling.javaapi.http.HttpProtocolBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.gatling.http.action.ws.WsInboundMessage;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

public class TournamentLoadSimulation extends Simulation {
  private static final String BASE_URL = property("baseUrl", "http://host.docker.internal:3000").replaceAll("/+$", "");
  private static final String WS_URL = websocketUrl();
  private static final int TOURNAMENT_ID = integerProperty("tournamentId", 204);
  private static final Duration TEST_DURATION = Duration.ofSeconds(integerProperty("testDurationSeconds", 600));
  private static final Duration GENERATION_TIMEOUT = Duration.ofSeconds(integerProperty("generationTimeoutSeconds", 600));
  private static final Duration VIEWER_RAMP_DURATION = Duration.ofSeconds(integerProperty("viewerRampSeconds", 30));
  private static final Duration WS_PROBE_INTERVAL = Duration.ofSeconds(integerProperty("wsProbeIntervalSeconds", 10));
  private static final Duration WS_RESPONSE_TIMEOUT = Duration.ofSeconds(integerProperty("wsResponseTimeoutSeconds", 10));
  private static final double SPECTATOR_RPS = doubleProperty("spectatorRequestsPerSecond", 3.0);
  private static final int LIVE_SCORE_VIEWERS = integerProperty("liveScoreViewers", 100);
  private static final int WS_MAX_P95_MS = integerProperty("wsMaxP95Ms", 1000);
  private static final int WS_UNMATCHED_BUFFER_SIZE = integerProperty("wsUnmatchedBufferSize", 1000);
  private static final String OPERATOR_EMAIL = property("operatorEmail", "test@test.com");
  private static final String OPERATOR_PASSWORD = property("operatorPassword", "password");
  private static final String MAT_PREFIX = "Load Test ";
  private static final Path PREPARED_MARKER = Path.of("/loadtests/run-state/prepared");

  private static volatile List<String> weightIds = List.of();
  private static volatile List<String> schoolIds = List.of();
  private static volatile long workloadDeadlineMillis;

  private static final Pattern MAT_ID_PATTERN = Pattern.compile("\\\"mat_id\\\":(\\d+)");
  private static final Pattern SELECTED_MATCH_ID_PATTERN = Pattern.compile("\\\"selected_match_id\\\":(null|\\d+)");
  private static final Pattern QUEUE_MATCH_ID_PATTERN = Pattern.compile("\\\"queue1_match_id\\\":(null|\\d+)");

  private final HttpProtocolBuilder httpProtocol = http
      .baseUrl(BASE_URL)
      .wsBaseUrl(WS_URL)
      .wsUnmatchedInboundMessageBufferSize(WS_UNMATCHED_BUFFER_SIZE)
      .acceptHeader("text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8")
      .acceptEncodingHeader("gzip, deflate")
      .userAgentHeader("WrestlingDev Gatling load test");

  private ChainBuilder ensureMat(int number) {
    String key = "loadMat" + number + "Id";
    String matPattern = "href=\"/mats/(\\d+)\">Mat " + MAT_PREFIX + number + "</a>";

    return exec(session -> session.remove(key))
        .exec(http("Prep - find mat " + number)
            .get("/tournaments/" + TOURNAMENT_ID)
            .check(status().is(200))
            .check(regex(matPattern).optional().saveAs(key)))
        .doIf(session -> session.get(key) == null).then(
            exec(http("Prep - create mat " + number)
                .post("/mats")
                .formParam("authenticity_token", "#{csrfToken}")
                .formParam("mat[name]", MAT_PREFIX + number)
                .formParam("mat[tournament_id]", Integer.toString(TOURNAMENT_ID))
                .check(status().in(200, 302, 303)))
                .exec(http("Prep - read created mat " + number)
                    .get("/tournaments/" + TOURNAMENT_ID)
                    .check(status().is(200))
                    .check(regex(matPattern).saveAs(key)))
        );
  }

  private final ScenarioBuilder preparation = scenario("Prepare tournament")
      .exec(http("Prep - login page")
          .get("/login")
          .check(status().is(200))
          .check(css("meta[name='csrf-token']", "content").saveAs("csrfToken")))
      .exec(http("Prep - login")
          .post("/login")
          .formParam("authenticity_token", "#{csrfToken}")
          .formParam("session[email]", OPERATOR_EMAIL)
          .formParam("session[password]", OPERATOR_PASSWORD)
          .check(status().is(200))
          .check(substring("Logged in successfully")))
      .exec(ensureMat(1), ensureMat(2), ensureMat(3), ensureMat(4), ensureMat(5))
      .exec(http("Prep - capture current first match")
          .get(session -> "/mats/" + session.getString("loadMat1Id") + "/state")
          .check(status().is(200))
          .check(regex("data-mat-state-match-id-value=\"(\\d+)\"").optional().saveAs("previousMatchId")))
      .exec(http("Prep - generate matches")
          .post("/tournaments/" + TOURNAMENT_ID + "/generate_matches")
          .formParam("authenticity_token", "#{csrfToken}")
          .check(status().in(200, 202, 204, 302, 303)))
      .exec(session -> session.set("generationReady", false))
      .asLongAsDuring(session -> !session.getBoolean("generationReady"), GENERATION_TIMEOUT).on(
          pause(Duration.ofSeconds(2)),
          exec(http("Prep - wait for newly generated matches")
              .get(session -> "/mats/" + session.getString("loadMat1Id") + "/state")
              .check(status().is(200))
              .check(regex("data-mat-state-match-id-value=\"(\\d+)\"").optional().saveAs("generatedMatchId"))),
          exec(session -> {
            String current = session.getString("generatedMatchId");
            String previous = session.getString("previousMatchId");
            boolean ready = current != null && (previous == null || !previous.equals(current));
            return session.set("generationReady", ready).remove("generatedMatchId");
          })
      )
      .exec(session -> session.getBoolean("generationReady") ? session : session.markAsFailed())
      .exitHereIfFailed()
      .exec(http("Prep - verify mats and collect tournament data")
          .get("/tournaments/" + TOURNAMENT_ID)
          .check(status().is(200))
          .check(regex("href=\"/weights/(\\d+)\"").findAll().saveAs("weightIds"))
          .check(regex("href=\"/schools/(\\d+)\"").findAll().saveAs("schoolIds")))
      .exec(session -> {
        weightIds = List.copyOf(session.getList("weightIds"));
        schoolIds = List.copyOf(session.getList("schoolIds"));
        if (weightIds.isEmpty() || schoolIds.isEmpty()) return session.markAsFailed();

        try {
          Files.createDirectories(PREPARED_MARKER.getParent());
          Files.writeString(PREPARED_MARKER, Integer.toString(TOURNAMENT_ID));
          workloadDeadlineMillis = System.currentTimeMillis() + TEST_DURATION.toMillis();
          return session;
        } catch (IOException exception) {
          return session.markAsFailed();
        }
      });

  private final ScenarioBuilder permanentUpMatchesViewers = scenario("Permanent full-screen up matches viewers")
      .exec(http("Permanent viewer - open full-screen up matches")
          .get("/tournaments/" + TOURNAMENT_ID + "/up_matches?print=true")
          .check(status().is(200))
          .check(regex("signed-stream-name=\"([^\"]+)\"").saveAs("signedStreamName")))
      .exec(ws("Permanent viewer - connect Action Cable").connect("/cable")
          .await(WS_RESPONSE_TIMEOUT).on(
              ws.checkTextMessage("Permanent viewer - receive Action Cable welcome")
                  .matching(substring("\"type\":\"welcome\""))))
      .exec(ws("Permanent viewer - subscribe to bout board")
          .sendText(session -> turboSubscription(session.getString("signedStreamName")))
          .await(WS_RESPONSE_TIMEOUT).on(
              ws.checkTextMessage("Permanent viewer - confirm bout board subscription")
                  .matching(substring("Turbo::StreamsChannel"), substring("confirm_subscription"))))
      .pause(session -> remainingWorkloadDuration())
      .exec(ws("Permanent viewer - close Action Cable").close());

  private final ScenarioBuilder liveScoreViewers = scenario("Persistent live scores viewers")
      .exec(http("Live scores viewer - open page")
          .get("/tournaments/" + TOURNAMENT_ID + "/live_scores")
          .check(status().is(200))
          .check(regex("data-match-scoreboard-mat-id-value=\"(\\d+)\"").findAll().saveAs("liveMatIds"))
          .check(regex("data-match-scoreboard-match-id-value=\"([1-9]\\d*)\"").findAll().saveAs("liveMatchIds")))
      .exec(session -> {
        List<String> matIds = session.getList("liveMatIds");
        List<String> matchIds = session.getList("liveMatchIds");
        Map<String, String> currentMatches = new LinkedHashMap<>();
        for (int index = 0; index < matIds.size(); index++) {
          currentMatches.put(matIds.get(index), index < matchIds.size() ? matchIds.get(index) : "0");
        }
        return session.set("currentMatchesByMat", currentMatches).set("probeIndex", 0);
      })
      .exec(ws("Live scores viewer - connect Action Cable").connect("/cable")
          .await(WS_RESPONSE_TIMEOUT).on(
              ws.checkTextMessage("Live scores viewer - receive Action Cable welcome")
                  .matching(substring("\"type\":\"welcome\""))))
      .foreach("#{liveMatIds}", "liveMatId").on(
          exec(ws("Live scores viewer - subscribe to mat")
              .sendText(session -> subscribe("MatScoreboardChannel", "mat_id", session.getString("liveMatId")))
              .await(WS_RESPONSE_TIMEOUT).on(
                  ws.checkTextMessage("Live scores viewer - confirm mat subscription")
                      .matching(substring("MatScoreboardChannel"), substring("confirm_subscription"))))
      )
      .foreach("#{liveMatchIds}", "liveMatchId").on(
          exec(ws("Live scores viewer - subscribe to match")
              .sendText(session -> subscribe("MatchChannel", "match_id", session.getString("liveMatchId")))
              .await(WS_RESPONSE_TIMEOUT).on(
                  ws.checkTextMessage("Live scores viewer - confirm match subscription")
                      .matching(substring("MatchChannel"), substring("confirm_subscription"))))
      )
      .exec(session -> session.set("viewerDurationMillis", remainingWorkloadDuration().toMillis()))
      .during(session -> Duration.ofMillis(session.getLong("viewerDurationMillis"))).on(
          pause(WS_PROBE_INTERVAL),
          followMatUpdates(),
          exec(session -> {
            Map<String, String> currentMatches = session.getMap("currentMatchesByMat");
            List<String> activeMatchIds = currentMatches.values().stream()
                .filter(matchId -> !"0".equals(matchId))
                .distinct()
                .toList();
            if (activeMatchIds.isEmpty()) return session.set("probeMatchId", "0");

            int probeIndex = session.getInt("probeIndex");
            String matchId = activeMatchIds.get(probeIndex % activeMatchIds.size());
            return session.set("probeMatchId", matchId).set("probeIndex", probeIndex + 1);
          }),
          doIf(session -> !"0".equals(session.getString("probeMatchId"))).then(
              exec(ws("Live scores viewer - websocket sync round trip")
                  .sendText(session -> channelAction("MatchChannel", "match_id", session.getString("probeMatchId"), "request_sync"))
                  .await(WS_RESPONSE_TIMEOUT).on(
                      ws.checkTextMessage("Live scores viewer - receive websocket sync")
                          .matching(
                              substring("MatchChannel"),
                              substring("\\\"match_id\\\":#{probeMatchId}"),
                              substring("\"message\""))))
          ),
          followMatUpdates()
      )
      .exec(ws("Live scores viewer - close Action Cable").close());

  private final ScenarioBuilder spectators = scenario("Anonymous spectator traffic")
      .randomSwitch().on(
          percent(30.0).then(exec(http("Spectator - up matches").get("/tournaments/" + TOURNAMENT_ID + "/up_matches"))),
          percent(10.0).then(exec(http("Spectator - team scores").get("/tournaments/" + TOURNAMENT_ID + "/team_scores"))),
          percent(30.0).then(exec(http("Spectator - random bracket").get(session -> "/tournaments/" + TOURNAMENT_ID + "/brackets/" + randomId(weightIds)))),
          percent(10.0).then(exec(http("Spectator - random school").get(session -> "/schools/" + randomId(schoolIds)))),
          percent(10.0).then(exec(http("Spectator - random weight").get(session -> "/weights/" + randomId(weightIds)))),
          percent(10.0).then(exec(http("Spectator - tournament page").get("/tournaments/" + TOURNAMENT_ID)))
      );

  public TournamentLoadSimulation() {
    Duration effectiveRamp = Duration.ofMillis(Math.min(VIEWER_RAMP_DURATION.toMillis(), Math.max(1, TEST_DURATION.toMillis() / 4)));
    setUp(
        preparation.injectOpen(atOnceUsers(1)).andThen(
            permanentUpMatchesViewers.injectOpen(rampUsers(3).during(effectiveRamp)),
            liveScoreViewers.injectOpen(rampUsers(LIVE_SCORE_VIEWERS).during(effectiveRamp)),
            spectators.injectOpen(constantUsersPerSec(SPECTATOR_RPS).during(TEST_DURATION))
        )
    ).protocols(httpProtocol).assertions(
        global().failedRequests().count().is(0L),
        details("Live scores viewer - receive websocket sync").responseTime().percentile(95).lt(WS_MAX_P95_MS)
    );
  }

  private ChainBuilder followMatUpdates() {
    return exec(ws.processUnmatchedMessages((messages, session) -> {
      Map<String, String> currentMatches = new LinkedHashMap<>(session.getMap("currentMatchesByMat"));
      List<String> changes = new ArrayList<>();

      for (WsInboundMessage inboundMessage : messages) {
        if (!(inboundMessage instanceof WsInboundMessage.Text textMessage)) continue;
        String body = textMessage.message();
        if (!body.contains("MatScoreboardChannel") || !body.contains("\"message\"")) continue;

        String matId = capture(MAT_ID_PATTERN, body);
        if (matId == null) continue;
        String selectedMatchId = capture(SELECTED_MATCH_ID_PATTERN, body);
        String queueMatchId = capture(QUEUE_MATCH_ID_PATTERN, body);
        String nextMatchId = numericId(selectedMatchId) ? selectedMatchId : numericId(queueMatchId) ? queueMatchId : "0";
        String oldMatchId = currentMatches.getOrDefault(matId, "0");
        if (!oldMatchId.equals(nextMatchId)) {
          changes.add(matId + ":" + oldMatchId + ":" + nextMatchId);
          currentMatches.put(matId, nextMatchId);
        }
      }

      return session.set("currentMatchesByMat", currentMatches).set("pendingMatchChanges", changes);
    })).foreach("#{pendingMatchChanges}", "pendingMatchChange").on(
        exec(session -> {
          String[] parts = session.getString("pendingMatchChange").split(":", -1);
          return session.set("changedMatId", parts[0]).set("oldMatchId", parts[1]).set("newMatchId", parts[2]);
        }),
        doIf(session -> !"0".equals(session.getString("oldMatchId"))).then(
            exec(ws("Live scores viewer - unsubscribe from previous match")
                .sendText(session -> unsubscribe("MatchChannel", "match_id", session.getString("oldMatchId"))))
        ),
        doIf(session -> !"0".equals(session.getString("newMatchId"))).then(
            exec(ws("Live scores viewer - subscribe to replacement match")
                .sendText(session -> subscribe("MatchChannel", "match_id", session.getString("newMatchId")))
                .await(WS_RESPONSE_TIMEOUT).on(
                    ws.checkTextMessage("Live scores viewer - confirm replacement match subscription")
                        .matching(
                            substring("MatchChannel"),
                            substring("\\\"match_id\\\":#{newMatchId}"),
                            substring("confirm_subscription"))))
        )
    );
  }

  private static String property(String name, String defaultValue) {
    String value = System.getProperty(name);
    return value == null || value.isBlank() ? defaultValue : value;
  }

  private static int integerProperty(String name, int defaultValue) {
    return Integer.parseInt(property(name, Integer.toString(defaultValue)));
  }

  private static double doubleProperty(String name, double defaultValue) {
    return Double.parseDouble(property(name, Double.toString(defaultValue)));
  }

  private static String websocketUrl() {
    String configured = property("wsUrl", "");
    if (!configured.isBlank()) return configured.replaceAll("/+$", "");
    if (BASE_URL.startsWith("https://")) return "wss://" + BASE_URL.substring("https://".length());
    if (BASE_URL.startsWith("http://")) return "ws://" + BASE_URL.substring("http://".length());
    throw new IllegalArgumentException("BASE_URL must start with http:// or https://");
  }

  private static String randomId(List<String> ids) {
    if (ids.isEmpty()) throw new IllegalStateException("Preparation did not discover tournament IDs");
    return ids.get(ThreadLocalRandom.current().nextInt(ids.size()));
  }

  private static String subscribe(String channel, String parameter, String value) {
    String identifier = "{\"channel\":\"" + channel + "\",\"" + parameter + "\":" + jsonValue(value) + "}";
    return "{\"command\":\"subscribe\",\"identifier\":" + quote(identifier) + "}";
  }

  private static String unsubscribe(String channel, String parameter, String value) {
    String identifier = "{\"channel\":\"" + channel + "\",\"" + parameter + "\":" + jsonValue(value) + "}";
    return "{\"command\":\"unsubscribe\",\"identifier\":" + quote(identifier) + "}";
  }

  private static String channelAction(String channel, String parameter, String value, String action) {
    String identifier = "{\"channel\":\"" + channel + "\",\"" + parameter + "\":" + jsonValue(value) + "}";
    String data = "{\"action\":\"" + action + "\"}";
    return "{\"command\":\"message\",\"identifier\":" + quote(identifier) + ",\"data\":" + quote(data) + "}";
  }

  private static String turboSubscription(String signedStreamName) {
    String identifier = "{\"channel\":\"Turbo::StreamsChannel\",\"signed_stream_name\":" + quote(signedStreamName) + "}";
    return "{\"command\":\"subscribe\",\"identifier\":" + quote(identifier) + "}";
  }

  private static String jsonValue(String value) {
    return value.matches("\\d+") ? value : quote(value);
  }

  private static String quote(String value) {
    return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n") + "\"";
  }

  private static String capture(Pattern pattern, String value) {
    Matcher matcher = pattern.matcher(value);
    return matcher.find() ? matcher.group(1) : null;
  }

  private static boolean numericId(String value) {
    return value != null && !"null".equals(value);
  }

  private static Duration remainingWorkloadDuration() {
    return Duration.ofMillis(Math.max(1, workloadDeadlineMillis - System.currentTimeMillis()));
  }
}
