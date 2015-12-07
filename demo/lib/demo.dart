@HtmlImport("demo.html")
library polymer_autonotify.demo;

import "package:polymer/polymer.dart";
import "package:web_components/web_components.dart" show HtmlImport;
import "package:polymer_autonotify/polymer_autonotify.dart";
import "package:observe/observe.dart";

import "package:polymer_elements/paper_item.dart";
import "package:polymer_elements/paper_input.dart";
import "package:polymer_elements/paper_icon_button.dart";
import "package:polymer_elements/iron_icons.dart";

import "package:polymer_datepicker/polymer_datepicker.dart";

import "dart:html";

@PolymerRegister("test-polymer-datepicker")
class TestPolymerAutonotify extends PolymerElement with AutonotifyBehavior, Observable {
 
 @observable @property DateTime myDate;
 


 TestPolymerAutonotify.created() : super.created();
}
