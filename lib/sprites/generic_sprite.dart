import 'package:graphx/graphx.dart';

class GenericSprite {
  String type;
  GDisplayObject display;
  double groundY = 0;
  double gravity = 1;
  double velY = 0.0;
  bool isJumping = false;

  GenericSprite([this.display, this.type]);

  double get rotation => display.rotation;

  set rotation(double value) => display.rotation = value;

  double get x => display.x;

  set x(double value) => display.x = value;

  double get y => display.y;

  set y(double value) => display.y = value;

  double get width => display.width;

  set width(double value) => display.width = value;

  double get height => display.height;

  set height(double value) => display.height = value;

  double get scaleX => display.scaleX;

  set scaleX(double value) => display.scaleX = value;

  double get scaleY => display.scaleY;

  set scaleY(double value) => display.scaleY = value;

  double get alpha => display.alpha;

  set alpha(double value) => display.alpha = value;
}