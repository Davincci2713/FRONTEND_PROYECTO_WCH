import 'package:flutter/material.dart';
import 'package:frontend_proyecto/screens/registro_de_usuario.dart';


class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(        // ← La imagen va ATRÁS
        image: DecorationImage(
          image: AssetImage('assets/img/fondo_login.png'),
          fit: BoxFit.cover,            // Cubre toda la pantalla
        ),
      ),

      
      child: Center(
        child: Container(
          width: 50,
          height: 50,
          color: Colors.white,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
              MaterialPageRoute(builder: (context) => RegistroDeUsuario()),
              );
            },
              child: Text(
                '¿No tienes cuenta? Crea una aquí',
              style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      )

      )
    );
  }
}