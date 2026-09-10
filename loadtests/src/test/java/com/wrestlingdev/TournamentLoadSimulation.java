package com.wrestlingdev;

import io.gatling.javaapi.core.Assertion;
import io.gatling.javaapi.core.ChainBuilder;
import io.gatling.javaapi.core.PopulationBuilder;
import io.gatling.javaapi.core.ScenarioBuilder;
import io.gatling.javaapi.core.Simulation;
import io.gatling.javaapi.http.HttpProtocolBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import io.gatling.http.action.ws.WsInboundMessage;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

public class TournamentLoadSimulation extends Simulation {
  private static final String BASE_URL = property("baseUrl", "http://host.docker.internal:3000").replaceAll("/+$", "");
  private static final String WS_URL = websocketUrl();
  private static final int TOURNAMENT_COUNT = boundedCount(integerProperty("tournamentCount", 1));
  private static final int LOAD_TEST_TOURNAMENT_BASE_ID = 205;
  private static final Duration TEST_DURATION = Duration.ofSeconds(integerProperty("testDurationSeconds", 600));
  private static final Duration GENERATION_TIMEOUT = Duration.ofSeconds(integerProperty("generationTimeoutSeconds", 600));
  private static final Duration VIEWER_RAMP_DURATION = Duration.ofSeconds(integerProperty("perTournamentViewerRampSeconds", 30));
  private static final Duration WS_PROBE_INTERVAL = Duration.ofSeconds(integerProperty("perTournamentWsProbeIntervalSeconds", 10));
  private static final Duration WS_RESPONSE_TIMEOUT = Duration.ofSeconds(integerProperty("wsResponseTimeoutSeconds", 10));
  private static final double SPECTATOR_RPS = doubleProperty("perTournamentSpectatorRequestsPerSecond", 3.0);
  private static final int LIVE_SCORE_VIEWERS = integerProperty("perTournamentLiveScoreViewers", 20);
  private static final int WS_MAX_P95_MS = integerProperty("wsMaxP95Ms", 1000);
  private static final int WS_UNMATCHED_BUFFER_SIZE = integerProperty("wsUnmatchedBufferSize", 1000);
  private static final String OPERATOR_EMAIL = property("operatorEmail", "test@test.com");
  private static final String OPERATOR_PASSWORD = property("operatorPassword", "password");
  private static final String MAT_PREFIX = "Load Test ";
  private static final Path PREPARED_MARKER = Path.of("/loadtests/run-state/prepared");

  private static final Map<Integer, List<String>> weightIdsByTournament = new ConcurrentHashMap<>();
  private static final Map<Integer, List<String>> schoolIdsByTournament = new ConcurrentHashMap<>();
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

  private ChainBuilder findMat(int tournamentId, int number) {
    String key = matKey(tournamentId, number);
    String matPattern = "href=\"/mats/(\\d+)\">Mat " + MAT_PREFIX + number + "</a>";

    return exec(http("Prep - find mat " + number + " (tournament " + tournamentId + ")")
        .get("/tournaments/" + tournamentId)
        .check(status().is(200))
        .check(regex(matPattern).saveAs(key)));
  }

  private ChainBuilder prepareTournament(int tournamentId) {
    String mat1Key = matKey(tournamentId, 1);
    String previousMatchKey = "t" + tournamentId + "PreviousMatchId";

    return exec(findMat(tournamentId, 1), findMat(tournamentId, 2), findMat(tournamentId, 3), findMat(tournamentId, 4), findMat(tournamentId, 5))
        .exec(http("Prep - capture current first match (tournament " + tournamentId + ")")
            .get(session -> "/mats/" + session.getString(mat1Key) + "/state")
            .check(status().is(200))
            .check(regex("data-mat-state-match-id-value=\"(\\d+)\"").optional().saveAs(previousMatchKey)))
        .exec(http("Prep - generate matches (tournament " + tournamentId + ")")
            .post("/tournaments/" + tournamentId + "/generate_matches")
            .formParam("authenticity_token", "#{csrfToken}")
            .check(status().in(200, 202, 204, 302, 303)))
        .exec(session -> session.set("generationReady", false))
        .asLongAsDuring(session -> !session.getBoolean("generationReady"), GENERATION_TIMEOUT).on(
            pause(Duration.ofSeconds(2)),
            exec(http("Prep - wait for newly generated matches (tournament " + tournamentId + ")")
                .get(session -> "/mats/" + session.getString(mat1Key) + "/state")
                .check(status().is(200))
                .check(regex("data-mat-state-match-id-value=\"(\\d+)\"").optional().saveAs("generatedMatchId"))),
            exec(session -> {
              String current = session.getString("generatedMatchId");
              String previous = session.getString(previousMatchKey);
              boolean ready = current != null && (previous == null || !previous.equals(current));
              return session.set("generationReady", ready).remove("generatedMatchId");
            })
        )
        .exec(session -> session.getBoolean("generationReady") ? session : session.markAsFailed())
        .exitHereIfFailed()
        .exec(http("Prep - collect tournament data (tournament " + tournamentId + ")")
            .get("/tournaments/" + tournamentId)
            .check(status().is(200))
            .check(regex("href=\"/weights/(\\d+)\"").findAll().saveAs("weightIds"))
            .check(regex("href=\"/schools/(\\d+)\"").findAll().saveAs("schoolIds")))
        .exec(session -> {
          List<String> weightIds = List.copyOf(session.getList("weightIds"));
          List<String> schoolIds = List.copyOf(session.getList("schoolIds"));
          if (weightIds.isEmpty() || schoolIds.isEmpty()) return session.markAsFailed();

          weightIdsByTournament.put(tournamentId, weightIds);
          schoolIdsByTournament.put(tournamentId, schoolIds);
          return session;
        });
  }

  private final ScenarioBuilder preparation = scenario("Prepare tournaments")
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
      .exec(prepareAllTournaments())
      .exec(session -> {
        try {
          Files.createDirectories(PREPARED_MARKER.getParent());
          Files.writeString(PREPARED_MARKER, loadTestTournamentIds().stream().map(String::valueOf).collect(Collectors.joining(",")));
          workloadDeadlineMillis = System.currentTimeMillis() + TEST_DURATION.toMillis();
          return session;
        } catch (IOException exception) {
          return session.markAsFailed();
        }
      });

  private ScenarioBuilder permanentUpMatchesViewers(int tournamentId) {
    return scenario("Permanent full-screen up matches viewers - tournament " + tournamentId)
        .exec(http("Permanent viewer - open full-screen up matches (tournament " + tournamentId + ")")
            .get("/tournaments/" + tournamentId + "/up_matches?print=true")
            .check(status().is(200))
            .check(regex("signed-stream-name=\"([^\"]+)\"").saveAs("signedStreamName")))
        .exec(ws("Permanent viewer - connect Action Cable (tournament " + tournamentId + ")").connect("/cable")
            .await(WS_RESPONSE_TIMEOUT).on(
                ws.checkTextMessage("Permanent viewer - receive Action Cable welcome (tournament " + tournamentId + ")")
                    .matching(substring("\"type\":\"welcome\""))))
        .exec(ws("Permanent viewer - subscribe to bout board (tournament " + tournamentId + ")")
            .sendText(session -> turboSubscription(session.getString("signedStreamName")))
            .await(WS_RESPONSE_TIMEOUT).on(
                ws.checkTextMessage("Permanent viewer - confirm bout board subscription (tournament " + tournamentId + ")")
                    .matching(substring("Turbo::StreamsChannel"), substring("confirm_subscription"))))
        .pause(session -> remainingWorkloadDuration())
        .exec(ws("Permanent viewer - close Action Cable (tournament " + tournamentId + ")").close());
  }

  private ScenarioBuilder liveScoreViewers(int tournamentId) {
    return scenario("Persistent live scores viewers - tournament " + tournamentId)
        .exec(http("Live scores viewer - open page (tournament " + tournamentId + ")")
            .get("/tournaments/" + tournamentId + "/live_scores")
            .check(status().is(200))
            .check(regex("data-match-scoreboard-mat-id-value=\"(\\d+)\"").findAll().saveAs("liveMatIds"))
            .check(regex("data-match-scoreboard-match-id-value=\"(\\d+)\"").findAll().saveAs("liveMatchIds")))
        .exec(session -> {
          List<String> matIds = session.getList("liveMatIds");
          List<String> matchIds = session.getList("liveMatchIds");
          Map<String, String> currentMatches = new LinkedHashMap<>();
          for (int index = 0; index < matIds.size(); index++) {
            currentMatches.put(matIds.get(index), index < matchIds.size() ? matchIds.get(index) : "0");
          }
          List<String> activeMatchIds = currentMatches.values().stream()
              .filter(matchId -> !"0".equals(matchId))
              .distinct()
              .toList();
          return session.set("currentMatchesByMat", currentMatches)
              .set("initialMatchIds", activeMatchIds)
              .set("confirmedMatchIds", new LinkedHashSet<String>())
              .set("probeIndex", 0);
        })
        .exec(ws("Live scores viewer - connect Action Cable (tournament " + tournamentId + ")").connect("/cable")
            .await(WS_RESPONSE_TIMEOUT).on(
                ws.checkTextMessage("Live scores viewer - receive Action Cable welcome (tournament " + tournamentId + ")")
                    .matching(substring("\"type\":\"welcome\""))))
        .foreach("#{liveMatIds}", "liveMatId").on(
            exec(ws("Live scores viewer - subscribe to mat (tournament " + tournamentId + ")")
                .sendText(session -> subscribe("MatScoreboardChannel", "mat_id", session.getString("liveMatId")))
                .await(WS_RESPONSE_TIMEOUT).on(
                    ws.checkTextMessage("Live scores viewer - confirm mat subscription (tournament " + tournamentId + ")")
                        .matching(substring("MatScoreboardChannel"), substring("confirm_subscription"))))
        )
        .foreach("#{initialMatchIds}", "liveMatchId").on(
            exec(ws("Live scores viewer - subscribe to match (tournament " + tournamentId + ")")
                .sendText(session -> subscribe("MatchChannel", "match_id", session.getString("liveMatchId")))
                .await(WS_RESPONSE_TIMEOUT).on(
                    ws.checkTextMessage("Live scores viewer - confirm match subscription (tournament " + tournamentId + ")")
                        .matching(substring("MatchChannel"), substring("confirm_subscription"))))
                .exitHereIfFailed()
                .exec(session -> {
                  Set<String> confirmed = new LinkedHashSet<>(session.getSet("confirmedMatchIds"));
                  confirmed.add(session.getString("liveMatchId"));
                  return session.set("confirmedMatchIds", confirmed);
                })
        )
        .exec(session -> session.set("viewerDurationMillis", remainingWorkloadDuration().toMillis()))
        .during(session -> Duration.ofMillis(session.getLong("viewerDurationMillis"))).on(
            pause(WS_PROBE_INTERVAL),
            followMatUpdates(tournamentId),
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
                exec(ws("Live scores viewer - websocket sync round trip (tournament " + tournamentId + ")")
                    .sendText(session -> channelAction("MatchChannel", "match_id", session.getString("probeMatchId"), "request_sync"))
                    .await(WS_RESPONSE_TIMEOUT).on(
                        ws.checkTextMessage("Live scores viewer - receive websocket sync (tournament " + tournamentId + ")")
                            .matching(
                                substring("MatchChannel"),
                                substring("\\\"match_id\\\":#{probeMatchId}"),
                                substring("\"message\""))))
            ),
            followMatUpdates(tournamentId)
        )
        .exec(ws("Live scores viewer - close Action Cable (tournament " + tournamentId + ")").close());
  }

  private ScenarioBuilder spectators(int tournamentId) {
    return scenario("Anonymous spectator traffic - tournament " + tournamentId)
        .randomSwitch().on(
            percent(30.0).then(exec(http("Spectator - up matches (tournament " + tournamentId + ")").get("/tournaments/" + tournamentId + "/up_matches"))),
            percent(10.0).then(exec(http("Spectator - team scores (tournament " + tournamentId + ")").get("/tournaments/" + tournamentId + "/team_scores"))),
            percent(30.0).then(exec(http("Spectator - random bracket (tournament " + tournamentId + ")").get(session -> "/tournaments/" + tournamentId + "/brackets/" + randomId(weightIdsByTournament.get(tournamentId))))),
            percent(10.0).then(exec(http("Spectator - random school (tournament " + tournamentId + ")").get(session -> "/schools/" + randomId(schoolIdsByTournament.get(tournamentId))))),
            percent(10.0).then(exec(http("Spectator - random weight (tournament " + tournamentId + ")").get(session -> "/weights/" + randomId(weightIdsByTournament.get(tournamentId))))),
            percent(10.0).then(exec(http("Spectator - tournament page (tournament " + tournamentId + ")").get("/tournaments/" + tournamentId)))
        );
  }

  public TournamentLoadSimulation() {
    Duration effectiveRamp = Duration.ofMillis(Math.min(VIEWER_RAMP_DURATION.toMillis(), Math.max(1, TEST_DURATION.toMillis() / 4)));
    List<PopulationBuilder> tournamentPopulations = new ArrayList<>();

    for (int tournamentId : loadTestTournamentIds()) {
      tournamentPopulations.add(permanentUpMatchesViewers(tournamentId).injectOpen(rampUsers(3).during(effectiveRamp)));
      tournamentPopulations.add(liveScoreViewers(tournamentId).injectOpen(rampUsers(LIVE_SCORE_VIEWERS).during(effectiveRamp)));
      tournamentPopulations.add(spectators(tournamentId).injectOpen(constantUsersPerSec(SPECTATOR_RPS).during(TEST_DURATION)));
    }

    PopulationBuilder population = preparation.injectOpen(atOnceUsers(1))
        .andThen(tournamentPopulations.toArray(PopulationBuilder[]::new));

    List<Assertion> assertions = new ArrayList<>();
    assertions.add(global().failedRequests().count().is(0L));
    for (int tournamentId : loadTestTournamentIds()) {
      assertions.add(
          details("Live scores viewer - receive websocket sync (tournament " + tournamentId + ")")
              .responseTime().percentile(95).lt(WS_MAX_P95_MS)
      );
    }

    setUp(population).protocols(httpProtocol).assertions(assertions.toArray(Assertion[]::new));
  }

  private ChainBuilder prepareAllTournaments() {
    ChainBuilder chain = exec(session -> session);
    for (int tournamentId : loadTestTournamentIds()) {
      chain = chain.exec(prepareTournament(tournamentId));
    }
    return chain;
  }

  private ChainBuilder followMatUpdates(int tournamentId) {
    return exec(ws.processUnmatchedMessages((messages, session) -> {
      Map<String, String> currentMatches = new LinkedHashMap<>(session.getMap("currentMatchesByMat"));

      for (WsInboundMessage inboundMessage : messages) {
        if (!(inboundMessage instanceof WsInboundMessage.Text textMessage)) continue;
        String body = textMessage.message();
        if (!body.contains("MatScoreboardChannel") || !body.contains("\"message\"")) continue;

        String matId = capture(MAT_ID_PATTERN, body);
        if (matId == null) continue;
        String selectedMatchId = capture(SELECTED_MATCH_ID_PATTERN, body);
        String queueMatchId = capture(QUEUE_MATCH_ID_PATTERN, body);
        String nextMatchId = numericId(selectedMatchId) ? selectedMatchId : numericId(queueMatchId) ? queueMatchId : "0";
        currentMatches.put(matId, nextMatchId);
      }

      Set<String> confirmedMatchIds = new LinkedHashSet<>(session.getSet("confirmedMatchIds"));
      Set<String> desiredMatchIds = currentMatches.values().stream()
          .filter(matchId -> !"0".equals(matchId))
          .collect(Collectors.toCollection(LinkedHashSet::new));
      List<String> unsubscribeIds = confirmedMatchIds.stream()
          .filter(matchId -> !desiredMatchIds.contains(matchId))
          .toList();
      List<String> subscribeIds = desiredMatchIds.stream()
          .filter(matchId -> !confirmedMatchIds.contains(matchId))
          .toList();

      return session.set("currentMatchesByMat", currentMatches)
          .set("unsubscribeMatchIds", unsubscribeIds)
          .set("subscribeMatchIds", subscribeIds);
    })).foreach("#{unsubscribeMatchIds}", "oldMatchId").on(
        exec(ws("Live scores viewer - unsubscribe from previous match (tournament " + tournamentId + ")")
            .sendText(session -> unsubscribe("MatchChannel", "match_id", session.getString("oldMatchId"))))
            .exec(session -> {
              Set<String> confirmed = new LinkedHashSet<>(session.getSet("confirmedMatchIds"));
              confirmed.remove(session.getString("oldMatchId"));
              return session.set("confirmedMatchIds", confirmed);
            })
    ).foreach("#{subscribeMatchIds}", "newMatchId").on(
        exec(ws("Live scores viewer - subscribe to replacement match (tournament " + tournamentId + ")")
            .sendText(session -> subscribe("MatchChannel", "match_id", session.getString("newMatchId")))
            .await(WS_RESPONSE_TIMEOUT).on(
                ws.checkTextMessage("Live scores viewer - confirm replacement match subscription (tournament " + tournamentId + ")")
                    .matching(
                        substring("MatchChannel"),
                        substring("\\\"match_id\\\":#{newMatchId}"),
                        substring("confirm_subscription"))))
            .exitHereIfFailed()
            .exec(session -> {
              Set<String> confirmed = new LinkedHashSet<>(session.getSet("confirmedMatchIds"));
              confirmed.add(session.getString("newMatchId"));
              return session.set("confirmedMatchIds", confirmed);
            })
    );
  }

  private static List<Integer> loadTestTournamentIds() {
    List<Integer> ids = new ArrayList<>();
    for (int index = 0; index < TOURNAMENT_COUNT; index++) {
      ids.add(LOAD_TEST_TOURNAMENT_BASE_ID + index);
    }
    return ids;
  }

  private static String matKey(int tournamentId, int number) {
    return "t" + tournamentId + "Mat" + number + "Id";
  }

  private static int boundedCount(int count) {
    return Math.min(10, Math.max(1, count));
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
    if (ids == null || ids.isEmpty()) throw new IllegalStateException("Preparation did not discover tournament IDs");
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
