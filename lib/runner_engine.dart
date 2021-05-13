import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphx/graphx.dart';

import 'sprites/enemy_sprite.dart';
import 'sprites/generic_sprite.dart';
import 'sprites/runner_sprite.dart';

class RunnerScene extends GSprite {
  int prevTime = 0;
  RunnerEngine engine;
  GTexture scoreBgTexture;

  @override
  Future<void> addedToStage() async {
    super.addedToStage();
    stage.color = kColorBlack;
    scoreBgTexture =
        await ResourceLoader.loadTexture('assets/images/scoreBg.png');
    init();
  }

  Future<void> init() async {
    engine = RunnerEngine(this, stage.stageWidth, stage.stageHeight);
    engine.onComplete = onEngineComplete;
    await engine.initScene();

    /// use like:
    /// Future.delayed(),
    /// WidgetBinding postframecallback,
    /// Timer()
    GTween.delayedCall(0.1, () {
      stage.onResized.add(_onStageResize);
      stage.onEnterFrame.add(_onEnterFrame);
    });
  }

  void _onStageResize() {
    engine.setSize(stage.stageWidth, stage.stageHeight);
  }

  void _onEnterFrame(double delta) {
    if (engine == null) return;

    /// similar to `delta` but `integer`.
    var fps = Math.round(1 / delta).toInt();
    engine.fps = fps;
    engine.onComplete ??= onEngineComplete;
    engine.step(delta * 1000);
  }

  void onEngineComplete() {
    removeChildren();
    stage.onResized.remove(_onStageResize);
    stage.onEnterFrame.remove(_onEnterFrame);
    final bg = GBitmap(scoreBgTexture);
    bg.alignPivot();
    bg.x = stage.stageWidth / 2;
    bg.y = stage.stageHeight / 2;
    addChild(bg);
    var score = GText(
      textStyle: TextStyle(
        color: kColorWhite,
        fontSize: 48,
      ),
    );
    score.text = '${engine.runnerScore}';
    score.validate();
    score.alignPivot();
    score.x = bg.x;
    score.y = bg.y - 10;
    addChild(score);
    stage.onMouseClick.addOnce(onRestartClicked);
    engine.removeFromParent(true);
    engine = null;
  }

  void onRestartClicked(e) {
    restartEngine();
  }

  void restartEngine() {
    removeChildren(0, -1, true);
    init();
  }
}

class RunnerEngine extends GSprite {
  GTexture cloudTexture, bg2Texture, bg1Texture, groundTopTexture;
  GTextureAtlas runnerAtlas;

  // double get stageWidth => stage.stageWidth;
  // double get stageHeight => stage.stageHeight;

  GSprite doc;
  double stageWidth, stageHeight;

  RunnerEngine([this.doc, this.stageWidth = 550, this.stageHeight = 400]) {
    doc?.addChild(this);
  }

  Future<void> initScene() async {
    isLoaded = false;
    _root = this;
    await loadAssets();
    init();
    isLoaded = true;
  }

  GSprite _root;
  GenericSprite sky, bgStrip1, bgStrip2;
  RunnerSprite runner;

  // protected var spritePool:Object = {};
  List<GenericSprite> groundList = [];
  List<GenericSprite> particleList = [];
  List<EnemySprite> enemyList = [];

  static const double SPEED = .33;
  int steps = 0;
  int startTime = 0;
  double groundY;
  GenericSprite lastGroundPiece;
  int incrementDelay = 250;
  int maxIncrement = 12000;
  int lastIncrement = 0;
  int fps = -1;
  int targetFPS = 58;
  int _runnerScore = 0;

  Function onComplete;

  @override
  void dispose() {
    isLoaded = false;
    groundList = [];
    particleList = [];
    enemyList = [];
    steps = 0;
    startTime = 0;
    lastGroundPiece = null;
    incrementDelay = 250;
    maxIncrement = 12000;
    fps = -1;
    targetFPS = 58;
    groundY = 0;
    lastIncrement = 0;
    _runnerScore = 0;
    onComplete = null;
    super.dispose();
  }

  Future<void> init() async {
    lastIncrement = getTimer() + 2000;
    // runnerScore = 0;
    await createChildren();
    sky.width = stageWidth;
    sky.height = stageHeight;
//BG1
    bgStrip1.height = stageHeight * .5 - 50;
    bgStrip1.scaleX = bgStrip1.scaleY;
    bgStrip1.y = stageHeight - bgStrip1.height;

    //BG2
    bgStrip2.height = stageHeight * .5 - 50;
    bgStrip2.scaleX = bgStrip2.scaleY;
    bgStrip2.y = stageHeight - bgStrip2.height;

    //Create Runner
    groundY = stageHeight - runner.height - 45;

    runner.x = stageWidth * .2;
    runner.y = groundY;
    runner.groundY = groundY;
    runner.enemyList = enemyList;

    //Add Ground
    addGround(3);

    //Add Particles
    addParticles(32);
  }

  void setSize(double sw, double sh) {
    stageWidth = sw;
    stageHeight = sh;
    /// stage resize.
    sky.width = stageWidth;
    sky.height = stageHeight;
    //BG1
    bgStrip1.height = stageHeight * .5 - 50;
    bgStrip1.scaleX = bgStrip1.scaleY;
    bgStrip1.y = stageHeight - bgStrip1.height;

    //BG2
    bgStrip2.height = stageHeight * .5 - 50;
    bgStrip2.scaleX = bgStrip2.scaleY;
    bgStrip2.y = stageHeight - bgStrip2.height;

    //Create Runner
    groundY = stageHeight - runner.height - 45;

    runner.x = stageWidth * .2;
    runner.groundY = groundY;

    enemyList.forEach((obj) {
      obj.groundY = groundY + runner.height - obj.height;
    });
    groundList.forEach((obj) {
      /// hack to try to move only the platform.
      if(obj.y > stageHeight*.78 ){
        obj.y = groundY + runner.height * .9;
      }
    });
  }

  int get runnerScore => _runnerScore;

  set runnerScore(int value) {
    _runnerScore = value;
    // FastStats.numChildren = runnerScore; //Hijack the ChildCount var of FastStats
  }

  Future<void> loadAssets() async {
    cloudTexture = await ResourceLoader.loadTexture('assets/images/cloud.png');
    bg2Texture = await ResourceLoader.loadTexture('assets/images/bg2.png');
    bg1Texture = await ResourceLoader.loadTexture('assets/images/bg1.png');
    groundTopTexture =
        await ResourceLoader.loadTexture('assets/images/groundTop.png');
    runnerAtlas =
        await ResourceLoader.loadTextureAtlas('assets/images/Runner.png');
  }

  Future<void> createChildren() async {
    var skyData = await createSkyData();
    sky = GenericSprite(_getBitmap(skyData));
    _root.addChild(sky.display);

    GBitmap bitmap1, bitmap2;
    GSprite sprite = GSprite();

    //BG Strip 1
    bitmap1 = _getBitmap(bg1Texture);
    sprite.addChild(bitmap1);
    bitmap2 = _getBitmap(bg1Texture);
    bitmap2.x = bitmap1.width;
    sprite.addChild(bitmap2);
    bgStrip1 = new GenericSprite(sprite);
    _root.addChild(bgStrip1.display);

    //BG Strip 2
    sprite = GSprite();
    bitmap1 = _getBitmap(bg2Texture);
    sprite.addChild(bitmap1);
    bitmap2 = _getBitmap(bg2Texture);
    bitmap2.x = bitmap1.width;
    sprite.addChild(bitmap2);
    bgStrip2 = GenericSprite(sprite);
    _root.addChild(bgStrip2.display);

    /// enemy textures.
    enemyTextures = getAtlasTextures('enemy');

    final mc = GMovieClip(frames: getAtlasTextures('swc.Runner'));
    mc.nativePaint.filterQuality = FilterQuality.none;
    // mc.scale = .5;
    runner = RunnerSprite(mc);
    _root.addChild(mc);
  }

  List<GTexture> getAtlasTextures(String prefix) {
    final out = <GTexture>[];
    final list = runnerAtlas.getNames(prefix: prefix);
    for (var name in list) {
      out.add(runnerAtlas.getTexture(name));
    }
    return out;
  }

  List<GTexture> enemyTextures;

  Future<GTexture> createSkyData() async {
    var rect = GSprite();
    rect.graphics.beginGradientFill(
      GradientType.linear,
      [Color(0xff000000), Color(0xff1E095E).withOpacity(.5)],
      ratios: [0, 255],
      rotation: Math.PI1_2,
    );
    rect.graphics.drawRect(0, 0, 128, 128);
    var skyData = await rect.createImageTexture();
    return skyData;
  }

  void addGround(int numPieces, [double height = 0]) {
    double lastX = 0;
    if (lastGroundPiece != null) {
      lastX = lastGroundPiece.x + lastGroundPiece.width - 3;
    }
    GenericSprite piece;
    for (var i = 0; i < numPieces; ++i) {
      piece = createGroundPiece();
      piece.y = groundY + runner.height * .9 - height;
      piece.x = lastX;
      lastX += (piece.width - 3);
      groundList.add(piece);
    }
    if (height == 0) {
      lastGroundPiece = piece;
    }
  }

  GenericSprite createGroundPiece() {
    var sprite = GenericSprite(_getBitmap(groundTopTexture), 'ground');
    _root.addChildAt(sprite.display, _root.getChildIndex(bgStrip2.display) + 1);
    return sprite;
  }

  GBitmap _getBitmap(GTexture texture) {
    final bmp = GBitmap(texture);
    bmp.nativePaint.filterQuality = FilterQuality.none;
    return bmp;
  }

  void addParticles(int numParticles) {
    final runnerH = runner.height;
    for (var i = 0; i < numParticles; i++) {
      final p = createParticle();
      p.x = runner.x - 10;
      p.y = runner.y + runnerH * .65 + runnerH * .25 * Math.random();
      particleList.add(p);
    }
  }

  void addEnemies([int numEnemies = 1]) {
    EnemySprite enemy;
    for (var i = 0; i < numEnemies; i++) {
      enemy = createEnemy();
      enemy.y = groundY + runner.height - enemy.height;
      enemy.x = stageWidth - 50 + Math.random() * 100;
      enemy.groundY = enemy.y;
      // enemy.groundY = groundY + enemy.height;
      enemy.y = -enemy.height;
      // enemyList.push(enemy);
      enemyList.add(enemy);
    }
  }

  EnemySprite createEnemy() {
    EnemySprite sprite = getSprite("enemy") as EnemySprite;
    if (sprite == null) {
      final mc = GMovieClip(frames: enemyTextures);
      mc.nativePaint.filterQuality = FilterQuality.none;
      sprite = EnemySprite(mc, "enemy");
    }
    // sprite ??= EnemySprite(GMovieClip(frames: enemyTextures), "enemy");
    _root.addChildAt(sprite.display, _root.getChildIndex(runner.display) - 1);
    return sprite;
  }

  GenericSprite createParticle() {
    var sprite = getSprite("particle");
    sprite ??= GenericSprite(_getBitmap(cloudTexture), "particle");
    _root.addChild(sprite.display);
    return sprite;
  }

  /// --- engine
  // void _onEnterFrame(double delta) {
  //   step(delta * 1000);
  // }

  /**
   * CORE ENGINE
   * You shouldn't need to override anything below this.
   **/

  bool isLoaded = false;

  /// elapsed gives us `milliseconds * 1000`
  void step(double elapsed) {
    if (!isLoaded) return;
    steps++;
    if (enemyList.isNotEmpty) {
      runnerScore = targetFPS * 10 + enemyList.length;
    } else {
      runnerScore = fps * 10;
    }
    updateRunner(elapsed);
    updateBg(elapsed);

    if (enemyList.isNotEmpty) {
      updateEnemies(elapsed);
    }
    if (groundList.isNotEmpty) {
      updateGround(elapsed);
    }
    updateParticles(elapsed);

    int increment = getTimer() - lastIncrement;
    // if (increment > 0) {
    //   onComplete?.call();
    //   stopEngine();
    // }
    if (fps >= targetFPS && increment > incrementDelay) {
      final count = 1 + enemyList.length ~/ 50;
      addEnemies(count);
      lastIncrement = getTimer();
    } else if (increment > maxIncrement) {
      //Test is Complete!
      onComplete?.call();
      stopEngine();
    }
  }

  void stopEngine() {
    _root.removeChildren();
    enemyList.length = 0;
    groundList.length = 0;
    particleList.length = 0;
  }

  /**
   * UPDATE METHODS
   * Probably won't need to override any of these, unless you're doing some advanced optimizations.
   **/
  void updateRunner(double elapsed) {
    runner.update();
    final mc = runner.display;
    if (mc is GMovieClip) {
      mc.gotoFrame(mc.currentFrame + 1);
    }
  }

  void updateBg(double elapsed) {
    bgStrip1.x -= elapsed * SPEED * .25;
    if (bgStrip1.x < -bgStrip1.width / 2) {
      bgStrip1.x = 0;
    }

    bgStrip2.x -= elapsed * SPEED * .5;
    if (bgStrip2.x < -bgStrip2.width / 2) {
      bgStrip2.x = 0;
    }
  }

  void updateEnemies(double elapsed) {
    EnemySprite enemy;
    for (var i = enemyList.length - 1; i >= 0; i--) {
      enemy = enemyList[i];
      enemy.x -= elapsed * .33;
      enemy.update();
      final mc = enemy.display;
      if (mc is GMovieClip) {
        mc.gotoFrame(mc.currentFrame + 1);
      }
      //Loop to other edge of screen
      if (enemy.x < -enemy.width) {
        enemy.x = stageWidth + 20;
      }
    }
  }

  void updateGround(double elapsed) {
//Add platforms
    if (steps % (fps > 30 ? 100 : 50) == 0) {
      addGround(1, stageHeight * .25 + stageHeight * .5 * Math.random());
    }

//Move Ground
    GenericSprite ground;
    List<int> toRemove = [];
    for (var i = groundList.length - 1; i >= 0; i--) {
      ground = groundList[i];
      ground.x -= elapsed * SPEED;
      //Remove ground
      if (ground.x < -ground.width * 3) {
        // groundList.splice(i, 1); /// not usable in Dart.
        toRemove.add(i);
        putSprite(ground);
        ground.display.removeFromParent();
      }
    }
    toRemove.forEach((idx) => groundList.removeAt(idx));
    //Add Ground
    var lastX = (lastGroundPiece != null)
        ? lastGroundPiece.x + lastGroundPiece.width
        : 0;
    if (lastX < stageWidth) {
      addGround(1, 0);
    }
  }

  void updateParticles(double elapsed) {
    if (steps % 3 == 0) {
      addParticles(3);
    }
    //Move Particles
    GenericSprite p;
    final toRemove = <int>[];
    for (var i = particleList.length - 1; i >= 0; i--) {
      p = particleList[i];
      p.x -= elapsed * SPEED * .5;
      p.alpha -= .02;
      p.scaleX -= .02;
      p.scaleY = p.scaleX;
      //Remove Particle
      if (p.alpha < 0 || p.scaleX < 0) {
        toRemove.add(i);
        // particleList.splice(i, 1);
        putSprite(p);
        p.display.removeFromParent();
      }
    }
    toRemove.forEach((idx) => particleList.removeAt(idx));
  }

  final spritePool = <String, List<GenericSprite>>{};

  GenericSprite getSprite(String type) {
    final a = spritePool[type];
    if (a != null && a.isNotEmpty) {
      return a.removeLast();
    }
    return null;
  }

  void putSprite(GenericSprite sprite) {
    //Rewind before we return ;)
    sprite.x = sprite.y = 0;
    sprite.scaleX = sprite.scaleY = 1;
    sprite.alpha = 1;
    sprite.rotation = 0;
    //Put in pool
    if (!spritePool.containsKey(sprite.type)) {
      spritePool[sprite.type] = [];
    }
    spritePool[sprite.type].add(sprite);
  }
}
