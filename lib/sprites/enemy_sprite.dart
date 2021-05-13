import 'package:graphx/graphx.dart';

import 'generic_sprite.dart';

class EnemySprite extends GenericSprite {
  EnemySprite([GDisplayObject display, String type]) : super(display, type){
    scaleX = scaleY = 2 ;
    scaleX *=-1;
  }

  void update() {
    velY += gravity;
    y += velY;
    if (y > groundY) {
      y = groundY;
      isJumping = false;
      velY = 0;
    }
    if (!isJumping && y == groundY && Math.random() < .02) {
      velY = -height * .25;
      isJumping = true;
    }
  }
}
