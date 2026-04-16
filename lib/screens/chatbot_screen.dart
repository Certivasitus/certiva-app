import 'dart:ui'; // Necesario para ImageFilter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/certiva_chat_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class CertivaChatScreen extends StatefulWidget {
  const CertivaChatScreen({Key? key}) : super(key: key);

  @override
  State<CertivaChatScreen> createState() => _CertivaChatScreenState();
}

class _CertivaChatScreenState extends State<CertivaChatScreen> {
  final CertivaChatService _chatService = CertivaChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  ChatConfig? _config;

  // Colores por defecto como versión anterior
  Color _colorAgente = const Color(0xFF1CE5C3);
  Color _colorUsuario = const Color(0xFFB18BD3);
  final Color _backgroundColor = const Color(0xFFF7F9FC);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _loadInitialData() async {
    // Esperamos unos milisegundos para que la animación de la ruta (Navigator.push) termine.
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _isLoading = true);
    try {
      _config = await _chatService.getConfig();
      if (_config != null) {
        _colorAgente = _hexToColor(_config!.colorPrimario);
        _colorUsuario = _hexToColor(_config!.colorUsuario);
      }

      final history = await _chatService.getHistory();
      if (history.isEmpty && _config != null) {
        final currentTimeStr = DateFormat('HH:mm').format(DateTime.now());
        history.add(
          ChatMessage(
            text: _config!.mensajeBienvenida,
            isUser: false,
            dateStr: currentTimeStr,
          ),
        );
      }

      setState(() => _messages = history);
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error inicializando chat: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    final currentTimeStr = DateFormat('HH:mm').format(DateTime.now());

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, dateStr: currentTimeStr));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final botReply = await _chatService.sendMessage(text);
      final replyTimeStr = DateFormat('HH:mm').format(DateTime.now());

      setState(() {
        _messages.add(ChatMessage(text: botReply, isUser: false, dateStr: replyTimeStr));
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error enviando mensaje: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _colorAgente.withOpacity(0.1),
                    child: Icon(Icons.auto_awesome, color: _colorAgente, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _config?.nombreAsistente ?? 'Cargando...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF444746)),
                  tooltip: 'Reiniciar Sesión',
                  onPressed: () {
                    _chatService.resetSession();
                    setState(() => _messages.clear());
                    _loadInitialData();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
              ),
              if (_isLoading) _buildLoadingIndicator(),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: _blob(300, _colorAgente.withOpacity(0.15)),
        ),
        Positioned(
          bottom: 200,
          left: -100,
          child: _blob(400, _colorUsuario.withOpacity(0.1)),
        ),
        Positioned(
          top: 300,
          right: -150,
          child: _blob(350, Colors.blue.withOpacity(0.05)),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Usamos un gradiente radial en lugar de BackdropFilter.
        // Es visualmente idéntico pero su costo de rendimiento es cero.
        gradient: RadialGradient(
          colors: [
            color, // Color sólido en el centro
            color.withOpacity(0.0), // Transparente en los bordes
          ],
          stops: const [0.1, 1.0], // Controla qué tan difuminado se ve
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _colorAgente,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bubbleColor = message.isUser ? _colorUsuario : _colorAgente;
    const textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _colorAgente.withOpacity(0.2),
              child: Icon(Icons.auto_awesome, size: 16, color: _colorAgente),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(message.isUser ? 24 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  HtmlWidget(
                    message.text,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.dateStr,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                ),
                child: TextField(
                  controller: _textController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Haz tu pregunta...',
                    hintStyle: const TextStyle(color: Color(0xFF8A8FA3)),
                    prefixIcon: const Icon(
                      Icons.forum_outlined,
                      size: 20,
                      color: Color(0xFF8A8FA3),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 42),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _colorAgente,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _handleSubmitted(_textController.text),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}