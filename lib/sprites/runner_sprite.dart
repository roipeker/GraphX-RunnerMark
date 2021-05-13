import 'package:graphx/graphx.dart';

import 'enemy_sprite.dart';
import 'generic_sprite.dart';

class RunnerSprite extends GenericSprite {
  List enemyList = <EnemySprite>[];

  RunnerSprite([GDisplayObject display, String type]) : super(display, type);

  void update() {
    // return ;
    velY += gravity;
    y += velY;
    if (y > groundY) {
      y = groundY;
      isJumping = false;
      velY = 0;
    }
    if (enemyList.isEmpty || isJumping) return;
    EnemySprite enemy;
    for (var i = 0, l = enemyList.length; i < l; i++) {
      enemy = enemyList[i];
      if (enemy.x > this.x && enemy.x - this.x < this.width * 1.5) {
        velY = -22;
        isJumping = true;
        break;
      }
    }
  }
}
