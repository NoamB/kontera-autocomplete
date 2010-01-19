package com.kontera.adcenter.components
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.controls.List;
	import mx.controls.TextInput;
	import mx.controls.listClasses.ListItemRenderer;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.managers.PopUpManager;

	[Event(name="fetchData", type="flash.events.Event")]
	[Event(name="dataFetched", type="flash.events.Event")]
	public class AutoComplete extends TextInput
	{
		private var _dropDown:List;

		public var labelField:String="name";               
		public var prompt:String;
		public var maxRows:int = 10;

		
		private var _caretIndex:int;
		private var _typedText:String;

		private var timer:Timer = new Timer(200,1);
		
		public function AutoComplete()
		{
			super();
			this.addEventListener(FocusEvent.FOCUS_IN, handleFocusIn);

			this.addEventListener(KeyboardEvent.KEY_DOWN, onAfterKeyDown, false, 100000);     
			this.addEventListener(Event.CHANGE, handleChange, false, 100000);
			this.addEventListener(MouseEvent.MOUSE_WHEEL,handleMouseWheel,false,10000);
			this.addEventListener(FlexEvent.CREATION_COMPLETE, init);
			this.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, handleTimerEvent);                
			editable=true;
			setStyle("color", 0x808080); // grey prompt
		}

		// selectedItem
		//////
		private var _selectedItem:Object;
		
		[Inspectable]
		[Bindable("siUpdated")]
		public function get selectedItem():Object
		{
			return _selectedItem;
		}
		
		public function set selectedItem(o:Object):void
		{
			_selectedItem = o;
		}
		
		// listStyleName
		//////
		private var _listStyleName : String;
		
		[Inspectable]
		public function get listStyleName() : String            { return _listStyleName }

		public function set listStyleName(value: String) : void                 
		{
			if (value && value!==_listStyleName)
			{
				_listStyleName= value;
				_listStyleNameChanged=true;
			}
		}

		private var _listStyleNameChanged: Boolean = false;
		
		// dataProvider
		//////
		private var _dataProvider:Object;
		
		public function set dataProvider(v:Object):void
		{
			_dataProvider = v;
			if (v)
			{
				_dropDown.labelField = labelField;			 
				setDropDownDataProvider(v);
			}
			else
			{
				hider();
			}
			dispatchEvent(new Event("dataFetched"));
		}

		private function setDropDownDataProvider(v:Object):void
		{
			_dropDown.dataProvider = v;
			try {

				var len:int = (v == null ? 0 : v.length());    
				_dropDown.rowCount = Math.min(maxRows, len);
				
				if (len > 0)
				{
					calcDropDownPosition();
					_dropDown.visible = true;
				}
				else
					hider();
				
				var w:Number = _dropDown.measureWidthOfItems();

				if (w < this.width)
					_dropDown.width = this.width;
				else if (w > this.maxWidth)
					_dropDown.width = this.maxWidth;
				else
					_dropDown.width = w;

				//NOT THE PROPER WAY....needs rewriting      
				_dropDown.validateNow();
				if (_dropDown.visible) 	
				{
				 	if (!stage.hasEventListener(MouseEvent.CLICK)) stage.addEventListener(MouseEvent.CLICK,handleClick,true);
				}				
			}
			catch(e:Error)
			{

			}
		}

		private function itemToLabel(item:Object):String
		{
			return (item is Object && item.hasOwnProperty(labelField)) ? item[labelField] : String(item);    
		}

		private function userChose(item:Object):void
		{
			if (item)
			{
				_selectedItem = item;
				//bad code ..should be in commitprop
				_typedText=itemToLabel(item);
				this.text=_typedText;
				hider();
				dispatchEvent(new Event("siUpdated"));
			}
		}
		
		private function moveSelection(keyCode : int) : void
		{
			var index : int = _dropDown.selectedIndex;
			if (index < 0)
			{
				index = 0;
			}
			else
			{                       
				switch (keyCode)
				{
					case Keyboard.UP:
						if (index > 0)
							index--;
						break;
					case Keyboard.DOWN:
						if (index < _dropDown.dataProvider.length-1)
							index++;
						break;                 
				}
			}
			_dropDown.selectedIndex = index;
			_dropDown.scrollToIndex(index);
		}

		private function hider():void
		{
			_dropDown.visible = false;
			if (stage.hasEventListener(MouseEvent.CLICK)) stage.removeEventListener(MouseEvent.CLICK,handleClick,true);
		}
		
		// Handlers
		//////
		private function init(event:Event):void
		{
			//FIXME: needs to be rewritten
			this.text = prompt;
			_dropDown = new List();
			PopUpManager.addPopUp(_dropDown,this);
			calcDropDownPosition();
			_dropDown.styleName="autocompleateList";
			_dropDown.visible = false;
			_dropDown.addEventListener(ListEvent.ITEM_CLICK,handleItemClick);				
		}
		
		public function calcDropDownPosition():void
		{
			var pt:Point = new Point();
			pt = this.localToGlobal(pt);
			_dropDown.x = pt.x
			_dropDown.y = pt.y + this.height;	
		}
				
		private function handleMouseWheel(event:MouseEvent):void
		{
			//fill mousewheelcode here
			//something with evt.delta
		}
		
		private function handleItemClick(event:ListEvent):void
		{
			userChose(event.itemRenderer.data);
		}

		private function handleChange(event:Event):void
		{
			var shouldFetchData:Boolean=true;
			_typedText = this.text;
			_selectedItem = null; 
			timer.reset();
			
			if ((!_dropDown.dataProvider)||(_dropDown.dataProvider.length===0)||(_typedText.length===0)) hider();
			if (_typedText.length===0) shouldFetchData=false;
			if (shouldFetchData) 
			{
				timer.start();
			}

			if (text != prompt)
				setStyle("color", 0x000000);
		}

		private function handleTimerEvent(event:TimerEvent):void
		{
			dispatchEvent(new Event("fetchData"));
		}
		
		private function handleFocusIn(event:Event):void
		{
			if (this.text == this.prompt)	this.text = "";
		}
		
		private function handleClick(event:MouseEvent):void
		{

			if ((event.target.parent===this)||(event.target.parent is ListItemRenderer)) event.preventDefault()
			else hider();
		}
		
		private function onFocusOut(event:FocusEvent) : void
		{
			if (_dataProvider != null) {
				if ((_dataProvider as XMLList).length() == 1) 
				{
					_dropDown.selectedItem = _dataProvider[0];	
				}
				userChose(_dropDown.selectedItem);
			}
		}
		private function onAfterKeyDown(event: KeyboardEvent) : void
		{
			var specialChar:Boolean;
			if (_dropDown.visible)	specialChar = true;
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.DOWN:
					moveSelection(event.keyCode);	 
					if (_dropDown.selectedItem != null)
					{
						var str:String = itemToLabel(_dropDown.selectedItem);
						this.text=str;
					}
					break;
				case Keyboard.TAB:
				case Keyboard.ENTER:
					for each (var obj:Object in _dropDown.dataProvider)
					{
						if (itemToLabel(obj).toUpperCase()===_typedText.toUpperCase()) _dropDown.selectedItem=obj;
					}	       
					userChose(_dropDown.selectedItem);
					break;
				case Keyboard.ESCAPE:
					hider();
					break;
				default:
					specialChar = false;
			}     
		}

	}//class

}//package

