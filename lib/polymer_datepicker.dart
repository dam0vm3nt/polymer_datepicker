import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:core_elements/core_overlay.dart';
import "dart:js" as js;

class Day extends Observable {
  @observable DateTime date;
  
  @observable bool selected;

  @observable bool today;

  @observable bool other;
  
  DateFormat fmt = new DateFormat("EEE");
  
  String get weekDay => fmt.format(date);
  
  Day(DateTime d,int curMonth,DateTime selectedDate) {
    this.date = d;

    other = curMonth != d.month;
    selected = (selectedDate != null&& d.day==selectedDate.day&&d.month==selectedDate.month);
    DateTime now = new DateTime.now();

    today = ( date.month == now.month && date.year == now.year && date.day == now.day);
  }
}

class Week extends Observable {
  @observable List<Day> days;
  
  Week(DateTime start,int curMonth,DateTime selectedDate) {
    days = new List.generate(7, (int i) => new Day(start.add(new Duration(days:i)),curMonth,selectedDate));
  }
}

/**
 * A Polymer datepicker element.
 *
 * Use selectedDate to get and set date (use a date object for value).
 * date format is hard coded for now using the only reasonable format i.e. D/M/Y H:M.
 * beware to init locale data before using this comp
 * 
 */

@CustomTag('date-picker')
class DatePicker extends PolymerElement {

  static const EventStreamProvider<CustomEvent> selectDateEvent = const EventStreamProvider<CustomEvent>('selectdate');

  @published String halign="left";

  @published String valign="top";

  @published DateTime selectedDate;
  @observable DateTime currentDate;

  @published String label;

  @published bool dateonly = false;
  
  @observable List<Week> month;

  Logger _logger = new Logger("DTPICK");
  
  DateFormat dateFormat = new DateFormat("MMMM yyyy");
  
  @ComputedProperty("dateFormat.format(currentDate)") get monthYear => readValue(#monthYear);
  
  DatePicker.created() : super.created() {
   // selectedDate = new DateTime.now();
    format = new DateFormat.yMd();
    if (!dateonly) {
      format.add_Hm();
    }
    currentDate = new DateTime.now();
    if (selectedDate!=null) {
      textDate = format.format(selectedDate);
    }
  }

  @observable bool pickerOpen = false;

  //bool _pickerOpenComplete = false;

  @override
  void attached() {
    super.attached();
    currentDateChanged(null,currentDate);
    
  }

  void doPos(Event e,var detail,Element el) {
    CoreOverlay ov = $['pick'] as CoreOverlay;

    // Ok : let's position the damn thing.
    Rectangle r = ov.parent.getBoundingClientRect();
    var left = r.left;
    var top = r.top;

    ov.style.position = "fixed";
    ov.style.left="${left}px";
    ov.style.top="${top}px";

    // Inform the component of positioning style
    ov.jsElement[r'dimensions'][r'position'] = new js.JsObject.jsify({
        "h":"left",
        "v":"top"
    });
  }

  void nextMonth() {
    _closePending=null;
    $['input'].focus();
    currentDate = currentDate.subtract(new Duration(days:currentDate.day-1));  
    currentDate = currentDate.add(new Duration(days:32));
    currentDate = currentDate.subtract(new Duration(days:currentDate.day-1));  
  }
  
  void prevMonth() {
    _closePending=null;
    $['input'].focus();
    currentDate = currentDate.subtract(new Duration(days:currentDate.day));
    currentDate = currentDate.subtract(new Duration(days:currentDate.day-1));     
  }
  
  DateFormat format = new DateFormat.yMd();
  
  @published String textDate;
  
  void selDate(Event evt,var detail,Node nd) {
    pickerOpen=false;
    selectedDate = new DateTime.fromMillisecondsSinceEpoch(int.parse((nd as Element).attributes["data-time"]));
  }
  
  void selectedDateChanged(DateTime oldDate,DateTime newDate) {
    _logger.fine("Date changed : ${selectedDate}");
    String newText;
    if (selectedDate!=null) {
      newText = format.format(selectedDate);
    } else {
      newText = null;
    }

    if (newText==textDate||_comingFromTextChange) {
      _comingFromTextChange = false;
      return;
    }
    textDate = newText;
    _logger.fine("Selected Date is ${selectedDate}");
    dispatchEvent(new CustomEvent("selectdate"));
    
  }

  bool _comingFromTextChange = false;
  
  void textDateChanged(String old,String newTextDate) {
    _logger.fine("Text changed : ${textDate}");
    try {
      DateTime newDate = format.parse(textDate);
      if (newDate == selectedDate) {
        return;
      }
      _comingFromTextChange = true;
      selectedDate=newDate;

      if (pickerOpen) {
        currentDate=selectedDate;
      }

    } catch (e) {
      _logger.fine("Invalid date :${textDate} : ${e}");
     // selectedDate = null;
    }
    _logger.fine("Parsed date : ${selectedDate}");
    dispatchEvent(new CustomEvent("selectdate"));
  }
  
  void currentDateChanged(DateTime oldDate,DateTime newDate ) {
    _updateMonth();
  }
  
  void _updateMonth() {
    _logger.fine("Create month");
      DateTime first = new DateTime.fromMillisecondsSinceEpoch(currentDate.millisecondsSinceEpoch);
      first = first.subtract(new Duration(days:first.day-1));
      while (first.weekday!=DateTime.MONDAY) {
        first = first.subtract(new Duration(days:1));
      }
      month = new List.generate(6, (int w) => new Week(first.add(new Duration(days:7*w)),currentDate.month,selectedDate));
      
  }

  void pickerOpened() {
    //$['input'].focus();
   // new Future.delayed(new Duration(milliseconds:100),() {$['input'].focus();_pickerOpenComplete=true;});
  }
  
  void showPicker() {
    if (selectedDate!=null) {
      currentDate = selectedDate;
    }
    _updateMonth();
    pickerOpen=true;
    //_pickerOpenComplete=false;
   // new Future.delayed(new Duration(milliseconds:1000),() {$['input'].focus();});
  }

  Future _closePending;

  void inputLeft() {
  //  if (_pickerOpenComplete) {
    Future f;
    _closePending = f = new Future.delayed(new Duration(milliseconds:100),() {if (_closePending == f) {pickerOpen=false;}});

  //  }
  }

  @override
  void detached() {
    super.detached();
    pickerOpen=false;

  }

  Stream<CustomEvent> get onSelectDate => selectDateEvent.forTarget(this);
}
