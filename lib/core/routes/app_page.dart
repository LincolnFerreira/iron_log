import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transição padrão do app: nova tela entra da direita,
/// tela anterior recua 30% para a esquerda (estilo iOS/Material You).
class AppPage<T> extends CustomTransitionPage<T> {
  AppPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionDuration: const Duration(milliseconds: 320),
         reverseTransitionDuration: const Duration(milliseconds: 280),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final enterCurve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOutCubic,
           );
           final exitCurve = CurvedAnimation(
             parent: secondaryAnimation,
             curve: Curves.easeInOutCubic,
           );

           return SlideTransition(
             // Tela anterior recua 30% para a esquerda
             position: Tween<Offset>(
               begin: Offset.zero,
               end: const Offset(-0.3, 0.0),
             ).animate(exitCurve),
             child: SlideTransition(
               // Nova tela entra da direita
               position: Tween<Offset>(
                 begin: const Offset(1.0, 0.0),
                 end: Offset.zero,
               ).animate(enterCurve),
               child: child,
             ),
           );
         },
       );
}
