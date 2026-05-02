import 'package:flutter/material.dart';
import 'package:frontend_proyecto/screens/RecuperarContrasena.dart';
import 'package:frontend_proyecto/screens/inicio.dart';
import 'package:frontend_proyecto/screens/registro_de_usuario.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/fondo_login.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
        ),
      ),
      child: Center(
        child: Container(
          width: 400,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsetsGeometry.all(24.0  ),
            child:  Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoLogin(),
                SizedBox(height: 100),
                UserField(),
                SizedBox(height: 5),
                PasswdField(),
                SizedBox(height: 7),
                RecuperarContrasenaLink(context),
                SizedBox(height: 25),
                IniciarSesionButton(context),
                SizedBox(height: 5),
                RegistroLink(context)
              ],
            ),
          )
          ),
        ),
      )
    );
  }


    Widget EncabezadoLogin(){
      return Column(
        children: [
          Icon(
            Icons.sports_soccer,
            size: 36,
            color: Colors.black,
          ),
          Text(
            'Iniciar Sesión',
            style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Ingresa a tu cuenta de mundial 2026 hub'
          )
        ],
      );
    }
    Widget UserField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correo Electronioc'),
        TextField(
          decoration: InputDecoration(
          labelText: 'Tu@correo.com',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.email)
          )
        ) 
      ],
    );
  }

    Widget PasswdField(){
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contraseña'),
        TextField(
          decoration: InputDecoration(
          labelText: '******',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.lock)
          )
        ) 
      ],
    );
  }

  Widget RecuperarContrasenaLink(BuildContext context){
    return TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Recuperarcontrasena()),
            );
            },
            child: Text(
              '¿Olvide mi contraseña?',
              style: TextStyle(
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          );
  }

Widget IniciarSesionButton(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Inicio()),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
      Text('Iniciar sesión'),
      SizedBox(width: 8),
      Icon(Icons.arrow_forward, size: 18),
  ],
),
  );
}

  Widget RegistroLink(BuildContext context) {
    return TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistroDeUsuario()),
            );
            },
            child: Text(
              '¿No tienes cuenta?, Registrate aqui',
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          );
  }
}