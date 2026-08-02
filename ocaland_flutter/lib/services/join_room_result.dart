import '../models/jugador.dart';
import '../models/partida.dart';

enum JoinOutcome { ok, salaLlena, noExiste, reconectar, error }

/// Resultado de intentar unirse a una sala por código. Si la partida ya
/// está en curso (alguien recargó la página, se cortó la conexión, etc.)
/// el resultado es `reconectar` con la lista de jugadores humanos
/// existentes para que la UI ofrezca "¿cuál de estos sos vos?".
class JoinRoomResult {
  final JoinOutcome outcome;
  final Partida? partida;
  final List<JugadorPartida> jugadoresParaReconectar;
  final String? errorMsg;

  JoinRoomResult.ok(this.partida) : outcome = JoinOutcome.ok, jugadoresParaReconectar = const [], errorMsg = null;
  JoinRoomResult.salaLlena() : outcome = JoinOutcome.salaLlena, partida = null, jugadoresParaReconectar = const [], errorMsg = null;
  JoinRoomResult.noExiste() : outcome = JoinOutcome.noExiste, partida = null, jugadoresParaReconectar = const [], errorMsg = null;
  JoinRoomResult.reconectar(this.partida, this.jugadoresParaReconectar) : outcome = JoinOutcome.reconectar, errorMsg = null;
  JoinRoomResult.error(this.errorMsg) : outcome = JoinOutcome.error, partida = null, jugadoresParaReconectar = const [];
}
