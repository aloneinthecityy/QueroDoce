import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app/services/notification_service.dart';

class AcompanharEntregaPage extends StatefulWidget {
  final String pedidoId;
  const AcompanharEntregaPage({super.key, required this.pedidoId});

  @override
  State<AcompanharEntregaPage> createState() => _AcompanharEntregaPageState();
}

class _AcompanharEntregaPageState extends State<AcompanharEntregaPage> {
  final MapController _mapController = MapController();

  // Estado para guardar a geolocalização do cliente
  LatLng? _posicaoCliente;
  String? _ultimoEnderecoBuscado;
  bool _buscandoEndereco = false;
  bool _cameraAjustada = false; // Controla se a câmera já enquadrou o cliente e entregador

  @override
  void dispose() {
    // Cancela a notificação persistente ao sair da tela
    NotificationService.cancelarNotificacaoPersistente();
    super.dispose();
  }

  // Função assíncrona para transformar o texto do endereço em coordenadas LatLng
  Future<void> _geocodeEndereco(String endereco) async {
    if (_buscandoEndereco || _ultimoEnderecoBuscado == endereco) return;
    _buscandoEndereco = true;
    _ultimoEnderecoBuscado = endereco;

    try {
      String queryEndereco = endereco.replaceAll(RegExp(r',?\s*CEP\s*\d{5}-?\d{3}', caseSensitive: false), '');
      queryEndereco = queryEndereco.trim();

      debugPrint('DEBUG - Geocodificando endereço limpo: "$queryEndereco" (Original: "$endereco")');

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(queryEndereco)}&countrycodes=br&format=json&limit=1'
      );

      final Map<String, String> headers = {};
      if (!kIsWeb) {
        headers['User-Agent'] = 'QueroDoceApp/1.0 (contato@querodoce.com)';
      }

      final response = await http.get(url, headers: headers);
      debugPrint('DEBUG - Resposta do Nominatim (Status ${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final double lat = double.parse(data[0]['lat']);
          final double lon = double.parse(data[0]['lon']);
          debugPrint('DEBUG - Coordenadas encontradas para o cliente: Lat $lat, Lng $lon');
          if (mounted) {
            setState(() {
              _posicaoCliente = LatLng(lat, lon);
            });
          }
        } else {
          debugPrint('DEBUG - Endereço não localizado pelo Nominatim.');
        }
      }
    } catch (e) {
      debugPrint('DEBUG - Erro ao geocodificar endereço: $e');
    } finally {
      _buscandoEndereco = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Acompanhar Entrega',
          style: GoogleFonts.pixelifySans(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF2BA0),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .doc(widget.pedidoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFEE0084)),
            );
          }

          final dados = snapshot.data!.data();
          if (dados == null) {
            return const Center(child: Text("Pedido não encontrado."));
          }

          final status = dados['status'] ?? '';
          final localizacao = dados['localizacaoEntregador'];
          final String? enderecoCliente = dados['enderecoEntrega'];

          // Reage ao status do pedido para notificação persistente
          if (status == 'em_entrega') {
            NotificationService.mostrarNotificacaoPersistente(
              titulo: '🛵 Pedido a caminho!',
              corpo: 'Seu pedido está sendo entregue agora.',
            );
          } else if (status == 'entregue' || status == 'cancelado') {
            NotificationService.cancelarNotificacaoPersistente();
          }

          if (enderecoCliente != null && enderecoCliente.isNotEmpty) {
            _geocodeEndereco(enderecoCliente);
          }

          if (status != 'em_entrega' || localizacao == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    size: 64,
                    color: Color(0xFFEE0084),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'aceito' || status == 'coletando'
                        ? "O entregador está preparando seu pedido!"
                        : "Pedido finalizado ou aguardando envio.",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final double lat = localizacao['latitude'];
          final double lng = localizacao['longitude'];
          final LatLng posicaoEntregador = LatLng(lat, lng);

          // Atualiza a câmera para enquadrar o entregador e o cliente (uma única vez ao carregar a rota)
          if (!_cameraAjustada) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_posicaoCliente != null) {
                final bounds = LatLngBounds.fromPoints([posicaoEntregador, _posicaoCliente!]);
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(70.0), // margem de segurança nas bordas do mapa
                  ),
                );
                _cameraAjustada = true;
              } else {
                _mapController.move(posicaoEntregador, 16.0);
              }
            });
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: posicaoEntregador,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.querodoce.app',
              ),
              MarkerLayer(
                markers: [
                // Marcador do entregador (Motinha)
                  Marker(
                    point: posicaoEntregador,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Color(0xFFEE0084),
                      size: 40,
                    ),
                  ),
                  // Marcador da residência do cliente (Casa)
                  if (_posicaoCliente != null)
                    Marker(
                      point: _posicaoCliente!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.home_work,
                        color: Color(0xFF3F51B5), // Azul para contraste claro com a moto rosa
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}