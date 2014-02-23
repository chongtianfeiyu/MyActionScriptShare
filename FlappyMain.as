package  {
	
	import flash.display.MovieClip;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.Sprite;
	import flash.ui.Keyboard;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
//	import flash.profiler.Telemetry;
	import CColision;
	import flash.net.SharedObject;
	
	public class FlappyMain extends MovieClip {
		//开始界面
		private var opening:Opening;
		//背景
		private var bgSpeed_X:Number=2.0;
		private var bgSprites:Sprite;
		private var bgCount_X:Number=0;
		//关卡
		private var barrierSpeed_X:Number=4.0;
		private var barrierVector:Array;
		private var groundSprites:Sprite;
		private var intervalFrames:Number=100;
		private var deltFrames:Number=0;
		private var spaceToThrough:Number=120;
		private var barrierHeight:Number;
		//小鸟
		private var bird:Bird;
		private var birdScale:Number=0.3 ;
		public var jumpForce:Number=-15;
		public var gravity:Number=2.0;
		public var vx:Number=0;
		public var vy:Number=0;
		private var birdSound:BirdSound;
		private var birdPos_X:Number=stage.stageWidth*0.3;
	    private var birdPos_Y:Number=stage.stageHeight*0.5;
		//设置计时器
		private var timer:Timer;
		private var period:Number=1;
		//游戏状态
		private const OPEN:int=0;
		private const START:int=1;
		private const GAMEOVER:int=2;
		private var gameState:int=0;
		//游戏得分
		private var pointText:TextField;
		private var myResult:Result;
		private var point:Number=10000;
		private var mysharedObject:SharedObject;
		public function FlappyMain() {
			initScene();
			//开始界面
			opening=new Opening();
			opening.x=stage.stageWidth/2-opening.width/2;
			addChild(opening);
			
			myResult=new Result();
			myResult.x=stage.stageWidth/2-myResult.width/2;
			myResult.y=stage.stageHeight/5;
			addChild(myResult);
			myResult.visible=false;
			stage.addEventListener(KeyboardEvent.KEY_DOWN,myKeydown);
		}
		//正式游戏
		private function startGame():void
		{
			opening.visible=false;
			pointText.visible=true;
			//initTimer();
			stage.addEventListener(Event.ENTER_FRAME,myEnterFrame);
			
		}
		//初始化场景
		private function initScene()
		{
			//添加背景
			addBackGround();
			//添加小鸟
			addBird();
			//添加分数显示
			addPointField();
			//初始化barrierVector,以及其他初始化
			barrierVector=new Array();
			barrierHeight=(new Barrier).height;
			birdSound=new BirdSound();
		}
		//添加背景
		private function addBackGround():void
		{
			var bg1:GrassGround=new GrassGround;
			groundSprites=new Sprite;
			groundSprites.addChild(bg1);
			groundSprites.y=-5;
			addChild(groundSprites);
		}
		//关卡设置
		private function setBarriers():void
		{
			deltFrames++;
			if(deltFrames<intervalFrames)
			  return;
			 intervalFrames=50;
			 deltFrames=0;
			 //trace("新的障碍物出现");
			 addBarrier();
		}
		private function addBarrier():void
		{
			var barrier_Top:Barrier=new Barrier();
			var barrier_Bottom:Barrier=new Barrier();
			barrier_Bottom.x=barrier_Top.x=stage.stageWidth;
			
			var ramdom_Y:Number=-Math.random()*barrierHeight*2/3;
			
			barrier_Top.y=ramdom_Y;
			barrier_Bottom.y=ramdom_Y+barrierHeight+spaceToThrough;
			
			
			addChild(barrier_Top);
			addChild(barrier_Bottom);
			
			barrierVector.push(barrier_Top);
			barrierVector.push(barrier_Bottom);
		}
		//添加小鸟
		private function addBird():void
		{
			bird=new Bird();
			bird.x=birdPos_X;
			bird.y=birdPos_Y;
			bird.scaleX=birdScale;
		    bird.scaleY=birdScale;
			addChild(bird);
		}
		//添加分数显示
		private function addPointField():void
		{
			var textForm:TextFormat=new TextFormat();
			textForm.size=25;
			textForm.bold=true;
			textForm.color=0xff2222;
			textForm.font="Stencil";
			pointText=new TextField;
			pointText.defaultTextFormat=textForm;
			pointText.text="0";
			pointText.x=stage.stageWidth/2-pointText.width/2;
			pointText.y=stage.stageHeight/5;
			addChild(pointText);
			pointText.visible=false;
		}
		//按每帧计算
		protected function myEnterFrame(e:Event):void
		{
			//移动小鸟
			moveBird();
			if(gameState==GAMEOVER)
			 {
				  opening.visible=true;
				  pointText.visible=true;
				  myResult.visible=true;
			      this.setChildIndex(opening,this.numChildren-1);
				  this.setChildIndex(myResult,this.numChildren-2);
				  this.setChildIndex(pointText,this.numChildren-3);
				  return;
			 }
			myResult.visible=false;
			//移动背景
			moveBG();
			//关卡设置
			setBarriers();
			moveBarriers();
			checkCollision();
			solvePoint();
		}
		private function moveBird():void
		{
			vy+=gravity;
			bird.y+=vy;
			if(bird.y<0)
			{
				bird.y=0;
			}
			if(bird.y>stage.stageHeight-bird.height)
			{
				bird.y=stage.stageHeight-bird.height;
				
				if(gameState==GAMEOVER)
				return;
				gameOver();
			}
		}
		private function moveBG():void
		{
			groundSprites.x-=bgSpeed_X;
			bgCount_X+=bgSpeed_X;
			if(bgCount_X>=groundSprites.width/2)
			{
				groundSprites.x+=bgCount_X;
				bgCount_X=0;
			}
		}
		private function moveBarriers():void
		{
			for each(var barrier:Barrier in barrierVector)//有each才是读取元素，否则读的是字符串
			{
				barrier.x-=barrierSpeed_X;
			}
		}
		//按键控制
		protected function myKeydown(e:KeyboardEvent):void
		{
			if(gameState==GAMEOVER||gameState==OPEN)
			{
				if(e.keyCode==Keyboard.ENTER)
				{
					bird.gotoAndPlay("normal");
					startGame();
					gameState=START;
					clearScene();
					bird.x=birdPos_X;
			        bird.y=birdPos_Y;
					vy=0;
					return;
				}
			   
			}
			if(e.keyCode==Keyboard.SPACE && gameState==START)
			{
				vy=jumpForce;
			}
		}
		//检查碰撞情况
		private function checkCollision():void
		{
			for each(var barrier:Barrier in barrierVector)
			{
				if(barrier.hitTestObject(bird))
				{
					gameOver();
				}
			}
		}
		//游戏结束
		private function gameOver():void
		{
			bird.gotoAndPlay("die");
			birdSound.play();
			updateResult();
			gameState=GAMEOVER;
		}
		//更新记录游戏成绩
		private function updateResult():void
		{
			//读取本地内容
			mysharedObject=SharedObject.getLocal("angryflappy");
			var high:Number=Number(mysharedObject.data.highest);
			trace(""+high);
			if(high>=point)
			  { 
			      myResult.highScore.text=high.toString();
				  myResult.resultPoint.text=point.toString();
				  myResult.history.text="历史最高";
			  }else
			  {
				  mysharedObject.data.highest=point.toString(); 
				  myResult.highScore.text=point.toString();
				   myResult.resultPoint.text=point.toString();
				    myResult.history.text="新记录";
				  mysharedObject.flush();
			  }
		}
		//消除场景
		private function clearScene():void
		{
			for each(var barrier:Barrier in barrierVector)
			{
				this.removeChild(barrier);
			}
			barrierVector.length=0;
		}
		//关于分数
		private function solvePoint():void
		{
			point=20000;
			for each(var barrier:Barrier in barrierVector)
			{
				if(barrier.x<=bird.x)
				{
					point--;
				}
			}
			point=point/2;
			pointText.text=point.toString();
		}
		/*
		//初始化，并启动计时器
		private function initTimer():void
		{
			timer=new Timer(period,0);
			timer.addEventListener(TimerEvent.TIMER,onTimer);
			timer.start();
		}
		//计时内容
		protected function onTimer(e:TimerEvent)
		{
			//移动小鸟
			moveBird();
			//移动背景
			moveBG();
			//关卡设置
			setBarriers();
			moveBarriers();
			checkCollision();
		}
		*/
	}
	
}
