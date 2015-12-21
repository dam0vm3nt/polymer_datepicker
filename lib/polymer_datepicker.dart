@HtmlImport("polymer_datepicker.html")
/// A simple date picker for dart and polymer
library polymer_datepicker;

import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';

import "package:web_components/web_components.dart" show HtmlImport;
import 'package:polymer_autonotify/polymer_autonotify.dart';
import "package:observe/observe.dart";

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import "dart:js" as js;

import "package:polymer_elements/paper_input.dart";
import "package:polymer_elements/paper_button.dart";
import "package:polymer_elements/paper_material.dart";
import "package:polymer_elements/paper_toggle_button.dart";

import "package:polymer_elements/iron_icon.dart";
import "package:polymer_elements/iron_fit_behavior.dart";
import "package:polymer_elements/iron_overlay_behavior.dart";
import "package:polymer_elements/iron_resizable_behavior.dart";

class Day extends Observable  {

static DateFormat fmt = new DateFormat("EEE");

  @observable DateTime date;

  @observable bool selected;

  @observable bool today;

  @observable bool other;

  @observable String weekDay;

  Day(DateTime d, int curMonth, DateTime selectedDate) : this.date = d
  {
    other = curMonth != d?.month;
    selected = date?.day == selectedDate?.day && date?.year == selectedDate?.year && date?.month == selectedDate?.month;
    DateTime now = new DateTime.now();
    today = date?.month == now.month && date?.year == now.year && date?.day == now.day;
    weekDay = fmt.format(date).substring(0,1);
  }
}

class Week extends Observable  {
  @observable List<Day> days;
  
  Week(DateTime start,int curMonth,DateTime selectedDate) {
    days = new List.generate(7, (int i) => new Day(start.add(new Duration(days:i)),curMonth,selectedDate));
  }
}

@PolymerRegister("date-picker-overlay")
class DatePickerOverlay extends PolymerElement with IronFitBehavior, IronResizableBehavior, IronOverlayBehavior {

  DatePickerOverlay.created() : super.created() {}

}

/**
 * A Polymer datepicker element.
 *
 * Use selectedDate to get and set date (use a date object for value).
 * date format is hard coded for now using the only reasonable format i.e. D/M/Y H:M.
 * beware to init locale data before using this comp
 * 
 */

const EventStreamProvider<CustomEvent> _selectDateEvent = const EventStreamProvider<CustomEvent>('select-date-changed');

@PolymerRegister('date-picker')
/// Date picker component for dart and polymer
///
/// Fires `select-date-changed` when selected date changes.
///
/// Example:
///
///     <date-picker 
///         select-date="{{myDateTimeField}}"
///         label="Select a date"
///         date-format="yyyy-MM-dd"
///         dateonly="true">
///     </date-picker>
///
class DatePicker extends PolymerElement with Observable, AutonotifyBehavior {
  /// A flag for field validation
  @observable @property bool required=false;

  @observable @property String halign="left";

  @observable @property String valign="top";

  /// A flag to enable / disable this field
  @observable @property bool disabled=false;

  /// Current selected date, bindable r/w, notify.
  @observable @Property(notify:true) DateTime selectedDate;

  @observable @property DateTime currentDate;

  /// Label displayed in the field
  @observable @property String label;

  /// A flag to select only date without time info (default: false)
  @observable @property bool dateonly = false;

  @observable @property List<Week> month;

  @observable @property Week firstWeek;

  DateFormat format = new DateFormat.yMd();

  /// Text version of the date bindable, r/w
  @observable @property String textDate;

  @Observe("required")
  void updateRequired(_)
  {
    print("req date $required");
    ($["input"] as PaperInput).validate();
  }


  Logger _logger = new Logger("DTPICK");
  
  DateFormat monthDateFormat = new DateFormat("MMMM yyyy");

  @Observe("currentDate")
  void computeMothYear([_]) {
    monthYear = currentDate!=null ?monthDateFormat.format(currentDate):"...";
  }

  @observable @property String monthYear;
  
  DatePicker.created() : super.created() {
    format = new DateFormat.yMd();
    if (!dateonly) {
      format.add_Hm();
    }
    currentDate = new DateTime.now();
    if (selectedDate!=null) {
      textDate = format.format(selectedDate);
    }
  }

  /// The date format (default: locale for `DateFormat.yMd`)
  @observable @property String dateFormat = new DateFormat.yMd().pattern;

  @Observe("dateonly,dateFormat")
  void changeDateFormat([_,__]) {
    format = new DateFormat(dateFormat);
    if (!dateonly) {
      format.add_Hm();
    }
    if (selectedDate!=null) {
      textDate = format.format(selectedDate);
    }
  }

  @observable @property bool pickerOpen = false;

  @override
  void attached() {
    super.attached();
    currentDateChanged(null,currentDate);
    
  }

  @reflectable
  void doPos(Event e,var detail) {
    DatePickerOverlay ov = $['pick'] as DatePickerOverlay;

    // Ok : let's position the damn thing.
    Rectangle r = ov.parent.getBoundingClientRect();
    var left = r.left;
    var top = r.top;

    ov.style.position = "fixed";
    ov.style.left="${left}px";
    ov.style.top="${top}px";

    // Inform the component of positioning style
    /*
    ov.jsElement[r'dimensions'][r'position'] = new js.JsObject.jsify({
        "h":"left",
        "v":"top"
    });*/
  }

  @reflectable
  void nextMonth([_,__]) {
    currentDate = currentDate.subtract(new Duration(days:currentDate.day-1));
    currentDate = currentDate.add(new Duration(days:32));
    currentDate = currentDate.subtract(new Duration(days:currentDate.day-1));  
  }

  bool _clickedIn=false;

  @reflectable
  void cancelClose([_,__]) {
    _clickedIn = true;
  }

  @reflectable
  void prevMonth([_,__]) {
    currentDate = currentDate.subtract(new Duration(days:currentDate.day));
    currentDate = currentDate.subtract(new Duration(days:currentDate.day-1));     
  }
  

  @reflectable
  void selDate(Event evt,var detail) {
    pickerOpen=false;
    //fire("change");

    Element el = evt.path.firstWhere((Element e) => e.attributes.containsKey("data-time"));
    String attr = el.attributes["data-time"];
    selectedDate = new DateTime.fromMillisecondsSinceEpoch(int.parse(attr));
  }

  @Observe("selectedDate")
  void selectedDateChanged([_]) {
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
    dispatchEvent(new CustomEvent("select-date-changed"));
    
  }

  bool _comingFromTextChange = false;

  @Observe("textDate")
  void textDateChanged([_]) {
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
    dispatchEvent(new CustomEvent("select-date-changed"));
  }

  @Observe("currentDate")
  void currentDateChanged([_,__]) {
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
      firstWeek = month.first;
  }



  void pickerOpened() {
  }

  @reflectable
  void showPicker([_,__]) {
    if (disabled) {
      return;
    }
    if (selectedDate!=null) {
      currentDate = selectedDate;
    }
    _updateMonth();
    pickerOpen=true;
  }


  @reflectable
  void inputLeft([_,__]) {
    if (_clickedIn) {
      _clickedIn=false;
      $['input'].focus();
      return;
    }
    pickerOpen=false;

    if (textDate==null||textDate.isEmpty) {
      selectedDate=null;
    }
    return;
  }

  @override
  void detached() {
    super.detached();
    pickerOpen=false;

  }

  @reflectable
  String computeInputClass(bool dateonly) =>  dateonly? 'input_dateonly to-validate' : 'input_full to-validate';

  @reflectable
  String computeDayClass(bool selected,bool other,bool today) {
    StringBuffer sb = new StringBuffer("dayCell");
    if (selected) {
      sb.write(" daySelected");
    }
    if (other) {
      sb.write(" dayOther");
    }
    if (today) {
      sb.write(" dayToday");
    }
    return sb.toString();
  }

  @reflectable
  String computeMillisecondsSinceEpoch(Day day) => day.date.millisecondsSinceEpoch.toString();

  @reflectable
  String computeDay(Day day) => day.date.day.toString();

  Stream<CustomEvent> get onSelectDate => _selectDateEvent.forTarget(this);
}
