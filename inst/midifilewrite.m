## Copyright (C) 2019 John Donoghue <john.donoghue@ieee.org>
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
## @deftypefn {} {} midifilewrite (@var{filename}, @var{msgs})
## @deftypefnx {} {} midifilewrite (@var{filename}, @var{msgs}, @var{optionname}, @var{optionvalue})
## Write a midifile
##
## @subsubheading Inputs
## @var{filename} - filename of file to open.@*
## @var{msg} - a midimsg struct or a cell array of midimsg containing data to write to file@*
## @var{optionname}, @var{optionvalue} - option value/name pairs@*
##
## Known options are:
## @table @asis
## @item format
## MIDI file format number. (0 (default), 1, 2)
## @end table
##
## Where format is 0, if a cell array is passed to midifilewrite, the midimsg values will
## be concatenated together before saving.
##
## Were format is not 0, the cell array is treated as tracks of misimsg.
##
## @subsubheading Outputs
## None
## @seealso{midifileread, midimsg}
## @end deftypefn

function midifilewrite(varargin)

  if nargin < 2
    error ("Expected filename and messages");
  endif

  filename = varargin{1};
  msg = varargin{2};

  if iscell(msg)
    for idx=1:length(msg)
       if !isa(msg{idx}, "midimsg")
         error ("Expected midimsg type messages in cell array");
       endif
    endfor
  elseif !isa(msg, "midimsg")
    error ("Expected midimsg type messages");
  endif

  if mod (nargin, 2) != 0
    error ("midifilewrite: expected property name, value pairs");
  endif
  if !iscellstr (varargin (3:2:nargin))
    error ("midifilewrite: expected property names to be strings");
  endif

  format = 0;
  for idx = 3:2:nargin
    propname = tolower (varargin{idx});
    propvalue = varargin{idx+1};

    if strcmp(propname, "format")
      if isnumeric(propvalue)
        format = int16(propvalue);
      else
        format = -1;
      endif
      if format != 1 && format != 2 && format != 0
        error ("format must be one of 0,1,2");
      endif
    else
      warning("Unknown option '%s' ignored", propname)
    endif
  endfor

  if format == 0
    trackcnt = 1;

    # if we had a cell string, make a single track list
    if iscell(msg)
      cellmsg = msg;
      msg = midimsg(0);
      for idx=1:length(cellmsg)
        msg = [msg cellmsg{idx}];
      endfor
    endif
 
  else
    # multi track mode, so make us a cell array
    if ! iscell(msg)
      msg = {msg};
    endif

    trackcnt = length(msg);
  endif

  fd = fopen (filename, "wb");

  unwind_protect
    # block hdr
    hdr = {};
    hdr.blocksize = 6;
    hdr.blocktype = "MThd";
    writeheader (fd, hdr);
    # info
    ticks_per_qtr = 1e3;
    frames = floor(ticks_per_qtr/256);
    ticks = mod(ticks_per_qtr, 256);
    fwrite (fd, format, "uint16", 0, "ieee-be");
    fwrite (fd, trackcnt, "uint16", 0, "ieee-be");
    fwrite (fd, frames, "uint8");
    fwrite (fd, ticks, "uint8");

    tempo = 6e7/120;

    if format == 0

      # the tracks
      fixpos = ftell (fd);
      hdr.blocksize = 0;
      hdr.blocktype = "MTrk";
      writeheader (fd, hdr);

      lasttime = 0;
      for idx=1:length(msg)
        a = msg(idx);
        if a.timestamp >= lasttime
          ts = (a.timestamp - lasttime);
        else
          ts = a.timestamp;
        endif
        lasttime = lasttime + ts;
        ts = (ts*1e6)/(tempo/ticks_per_qtr);
        setvariable (fd, ts);
        fwrite (fd, a.msgbytes);

        # TODO: if come across any tempo message, set tempo to it
      endfor

      # write eot and fix the header
      fwrite (fd, uint8([0x01 0xff 0x2f 0x00]));

      # fix the size of the track
      cpos = ftell (fd);
      len = cpos - fixpos - 8;
      fseek (fd, fixpos, SEEK_SET);

      hdr.blocksize = len;
      hdr.blocktype = "MTrk";
      writeheader (fd, hdr);

      fseek (fd, cpos, SEEK_SET);

    else
      # the tracks
      for t=1:length(msg)
        fixpos = ftell (fd);
        hdr.blocksize = 0;
        hdr.blocktype = "MTrk";
        writeheader (fd, hdr);

        lasttime = 0;
        m = msg{t};
        for idx=1:length(m)
          a = m(idx);
          if a.timestamp >= lasttime
            ts = (a.timestamp - lasttime);
          else
            ts = a.timestamp;
          endif
          lasttime = lasttime + ts;
          ts = (ts*1e6)/(tempo/ticks_per_qtr);
          setvariable (fd, ts);
          fwrite (fd, a.msgbytes);
        endfor

        # write eot and fix the header
        fwrite (fd, uint8([0x01 0xff 0x2f 0x00]));

        # fix the size of the track
        cpos = ftell (fd);
        len = cpos - fixpos - 8;
        fseek (fd, fixpos, SEEK_SET);

        hdr.blocksize = len;
        hdr.blocktype = "MTrk";
        writeheader (fd, hdr);

        fseek (fd, cpos, SEEK_SET);

      endfor
    endif
   
  unwind_protect_cleanup
    fclose (fd);
  end_unwind_protect

endfunction

%!shared testname
%! testname = tempname;

%!test
%! data = midimsg("note", 1, 60, 100, 2);
%! midifilewrite(testname, data);
%! info = midifileinfo(testname);
%! t = info.header;
%! assert(info.header.format, 0);
%! assert(info.header.tracks, 1);
%! msg = midifileread(testname);
%! assert(msg(1).msgbytes, uint8([0x90 0x3C 0x64]));
%! assert(msg(2).msgbytes, uint8([0x90 0x3C 0x00]));
%! assert(msg(2).timestamp, 2);

%!test
%! data = midimsg("note", 1, 60, 100, 2);
%!
%! midifilewrite(testname, data, 'format', 0);
%! info = midifileinfo(testname);
%! assert(info.header.format, 0);
%! assert(info.header.tracks, 1);
%! msg = midifileread(testname);
%! assert(length(msg), 2);
%!
%! midifilewrite(testname, data, 'format', 1);
%! info = midifileinfo(testname);
%! assert(info.header.format, 1);
%! assert(info.header.tracks, 1);
%! msg = midifileread(testname);
%! assert(length(msg), 2);
%!
%! midifilewrite(testname, {data, data}, 'format', 0);
%! info = midifileinfo(testname);
%! assert(info.header.format, 0);
%! assert(info.header.tracks, 1);
%! msg = midifileread(testname);
%! assert(length(msg), 4);
%!
%! midifilewrite(testname, {data, data}, 'format', 1);
%! info = midifileinfo(testname);
%! assert(info.header.format, 1);
%! assert(info.header.tracks, 2);
%! msg = midifileread(testname);
%! assert(length(msg), 4);

%!test
%! if exist (testname, 'file');
%!   delete (testname);
%! end
