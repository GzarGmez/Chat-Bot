import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener el ancho y alto de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 22, 74, 147), Color.fromARGB(255, 52, 76, 154)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Logo en la parte superior
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/logo.png',
                      height: screenWidth * 0.25, // El tamaño del logo depende del ancho de la pantalla
                      width: screenWidth * 0.25,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Información
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Universidad Politécnica de Chiapas',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(221, 58, 58, 58),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Divider(height: 30, thickness: 1),
                        _buildInfoText('Ingeniería en Desarrollo de Software'),
                        _buildInfoText('Andrés Guízar Gómez'),
                        _buildInfoText('213360'),
                        _buildInfoText('Grupo B'),
                        _buildInfoText('Programación para móviles II'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Botones de acción
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Ir al Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 3, 6, 86),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1, // Tamaño adaptativo para los botones
                            vertical: 15,
                          ),
                          textStyle: TextStyle(fontSize: screenWidth * 0.045),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/chat');
                        },
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          textStyle: TextStyle(
                            fontSize: screenWidth * 0.04,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onPressed: () async {
                          const url = 'https://github.com/GzarGmez/Chat-Bot.git';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            throw 'Error 404 $url';
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }
}
