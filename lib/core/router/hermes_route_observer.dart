import 'package:flutter/material.dart';

/// Sinaliza quando uma página deixa de ser a rota visível sem precisar acoplar
/// widgets de produto ao [GoRouter].
final hermesRouteObserver = RouteObserver<PageRoute<dynamic>>();
