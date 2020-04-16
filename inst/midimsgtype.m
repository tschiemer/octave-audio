## Copyright (C) 2020 John Donoghue <john.donoghue@ieee.org>
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {} {} midimsgtype
## A midimsg type enumeration for values of the midimsg type.
##
## Enumeration values are:
## @multitable @columnfractions .2 .4 .3
## @item Data        @tab Stop            @tab SongPositionPointer 
## @item PolyOn      @tab PolyKeyPressure @tab NoteOff
## @item EOX         @tab ActiveSensing   @tab SongSelect
## @item MonoOn      @tab ChannelPressure @tab ControllChange
## @item TimingClock @tab SystemReset     @tab AlLSoundOff
## @item OmniOn      @tab PitchBendChange @tab ProgramChange
## @item Start       @tab TuneRequest     @tab ResetAllControllers
## @item OmniOff     @tab Undefined       @tab SystemExclusive
## @item Continue    @tab MIDITimeCodeQuarterFrame @tab LocalControl
## @item AllNotesOff @tab                 @tab
## @end multitable
##
##
## The enumeration value can be used instead of a string in midimsg creation.
##
## @subsubheading Examples
## Use both a string and a midimsgtype for the type parameter of a midimsg.
## @example
## @code {
## # both statements are equivalent
## msg = midimsg('NoteOn', 1, 60, 100);
## msg = midimsg(midimsgtype.NoteOn, 1, 60, 100);
## }
## @end example
##
## @seealso{midimsg}
## @end deftypefn

classdef midimsgtype
  # enumeration doesnt work yet in octave
  #enumeration
  #  Stop ("Stop")
  #endenumeration

  properties  (Access = private)
    value = ""
  endproperties

  # dont allow external creation of objects
  methods (Access = private, Hidden = true)
    function this = midimsgtype(value)
      this.value = value;
    endfunction
  endmethods

  methods
    function tf = isenum(this)
      tf = true;
    endfunction

    # ismember
	    
    function tf = eq(this, val)
      if isobject(val) && strcmp(class(val), "midimsgtype")
        val = val.value;
      endif

      if ischar(val) == false
        tf = false;
      else
        tf = strcmpi(this.value, val);
      endif
    endfunction

    function s = char(this)
      s = this.value;
    endfunction
    
    function a = disp(this)
      if nargout == 0
        disp(this.value);
      else
        a = [this.value "\n"];
      endif
    endfunction

    function display(this)
      printf("%s = %s\n", inputname(1), this.value);
    endfunction
  endmethods

  # methods we will use to fake as readonly enum values
  methods (Static = true)
    function c = NoteOn()
      persistent v = midimsgtype("NoteOn");
      c = v;
    endfunction
    function c = NoteOff()
      persistent v = midimsgtype("NoteOff");
      c = v;
    endfunction
    function c = ControlChange()
      persistent v = midimsgtype("ControlChange");
      c = v;
    endfunction
    function c = ProgramChange()
      persistent v = midimsgtype("ProgramChange");
      c = v;
    endfunction
    function c = SystemExclusive()
      persistent v = midimsgtype("SystemExclusive");
      c = v;
    endfunction
    function c = Data()
      persistent v = midimsgtype("Data");
      c = v;
    endfunction
    function c = EOX()
      persistent v = midimsgtype("EOX");
      c = v;
    endfunction
    function c = TimingClock()
      persistent v = midimsgtype("TimingClock");
      c = v;
    endfunction
    function c = Start()
      persistent v = midimsgtype("Start");
      c = v;
    endfunction
    function c = Continue()
      persistent v = midimsgtype("Continue");
      c = v;
    endfunction
    function c = Stop()
      persistent v = midimsgtype("Stop");
      c = v;
    endfunction
    function c = ActiveSensing()
      persistent v = midimsgtype("ActiveSensing");
      c = v;
    endfunction
    function c = SystemReset()
      persistent v = midimsgtype("SystemReset");
      c = v;
    endfunction
    function c = TuneRequest()
      persistent v = midimsgtype("TuneRequest");
      c = v;
    endfunction
    function c = MIDITimeCodeQuarterFrame()
      persistent v = midimsgtype("MIDITimeCodeQuarterFrame");
      c = v;
    endfunction
    function c = SongPositionPointer()
      persistent v = midimsgtype("SongPositionPointer");
      c = v;
    endfunction
    function c = SongSelect()
      persistent v = midimsgtype("SongSelect");
      c = v;
    endfunction
    function c = AllSoundOff()
      persistent v = midimsgtype("AllSoundOff");
      c = v;
    endfunction
    function c = ResetAllControllers()
      persistent v = midimsgtype("ResetAllControllers");
      c = v;
    endfunction
    function c = LocalControl()
      persistent v = midimsgtype("LocalControl");
      c = v;
    endfunction
    function c = PolyOn()
      persistent v = midimsgtype("PolyOn");
      c = v;
    endfunction
    function c = MonoOn()
      persistent v = midimsgtype("MonoOn");
      c = v;
    endfunction
    function c = OmniOff()
      persistent v = midimsgtype("OmniOff");
      c = v;
    endfunction
    function c = OmniOn()
      persistent v = midimsgtype("OmniOn");
      c = v;
    endfunction
    function c = AllNotesOff()
      persistent v = midimsgtype("AllNotesOff");
      c = v;
    endfunction
    function c = PolyKeyPressure()
      persistent v = midimsgtype("PolyKeyPressure");
      c = v;
    endfunction
    function c = ChannelPressure()
      persistent v = midimsgtype("ChannelPressure");
      c = v;
    endfunction
    function c = PitchBendChange()
      persistent v = midimsgtype("PitchBendChange");
      c = v;
    endfunction
    function c = Undefined()
      persistent v = midimsgtype("Undefined");
      c = v;
    endfunction
  endmethods
endclassdef

%!fail midimsg.InvalidEnumValue

%!test 
%! t = midimsgtype.NoteOn;
%! assert (class(t) == "midimsgtype");
%! c = char (t);
%! assert (class(c) == "char");
%! assert (c == "NoteOn");

%!test
%! t = midimsgtype.NoteOff;
%! assert (isenum(t));

%!test
%! t = midimsgtype.NoteOn;
%! assert (t == "NoteOn")