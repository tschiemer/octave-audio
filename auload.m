## Copyright (C) 1999 Paul Kienzle
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

## usage: [x, fs, sampleformat] = auload('filename.ext')
##
## Reads an audio waveform from a file.  Returns the audio samples in
## data, one column per channel, one row per time slice.  Also returns
## the sample rate and stored format (one of ulaw, alaw, char, short,
## long, float, double). The sample value will be normalized to the
## range [-1,1) regardless of the stored format.  This does not do any
## level correction or DC offset correction on the samples.
##
## Example
##    [x, fs] = auload(file_in_loadpath("sample.wav"));
##    auplot(x,fs);

## 2001-09-04 Paul Kienzle <pkienzle@users.sf.net>
## * skip unknown blocks in WAVE format.
## 2001-09-05 Paul Kienzle <pkienzle@users.sf.net>
## * remove debugging stuff from AIFF format.
## * use data length if it is given rather than reading to the end of file.

function [data, rate, sampleformat] = auload(path)

  if (nargin != 1)
    usage("[x, fs, sampleformat] = auload('filename.ext')");
  end
  data = [];       # if error then read nothing
  rate = 8000;
  sampleformat = 'ulaw';
  ext = rindex(path, '.');
  if (ext == 0)
    usage('x = auload(filename.ext)');
  end
  ext = tolower(substr(path, ext+1, length(path)-ext));

  [file, msg] = fopen(path, 'r');
  if (file == -1)
    error([ msg, ": ", path]);
  end

  msg = sprintf('Invalid audio header: %s', path);
  ## Microsoft .wav format
  if strcmp(ext,'wav') 

    ## Header format obtained from sox/wav.c
    ## April 15, 1992
    ## Copyright 1992 Rick Richardson
    ## Copyright 1991 Lance Norskog And Sundry Contributors
    ## This source code is freely redistributable and may be used for
    ## any purpose.  This copyright notice must be maintained. 
    ## Lance Norskog And Sundry Contributors are not responsible for 
    ## the consequences of using this software.

    ## check the file magic header bytes
    arch = 'ieee-le';
    str = setstr(fread(file, 4, 'char')');
    if !strcmp(str, 'RIFF')
      error(msg);
    end
    len = fread(file, 1, 'long', 0, arch);
    str = setstr(fread(file, 4, 'char')');
    if !strcmp(str, 'WAVE')
      error(msg);
    end

    ## skip to the "fmt " section, ignoring everything else
    while (1)
      if feof(file)
      	error(msg);
      end
      str = setstr(fread(file, 4, 'char')');
      len = fread(file, 1, 'long', 0, arch);
      if strcmp(str, 'fmt ')
	break;
      end
      fseek(file, len, SEEK_CUR);
    end

    ## read the "fmt " section
    formatid = fread(file, 1, 'short', 0, arch);
    channels = fread(file, 1, 'short', 0, arch);
    rate = fread(file, 1, 'long', 0, arch);
    fread(file, 1, 'long', 0, arch);
    fread(file, 1, 'short', 0, arch);
    bits = fread(file, 1, 'short', 0, arch);
    fseek(file, len-16, SEEK_CUR);

    ## skip to the "data" section, ignoring everything else
    while (1)
      if feof(file)
      	error(msg);
      end
      str = setstr(fread(file, 4, 'char')');
      len = fread(file, 1, 'long', 0, arch);
      if strcmp(str, 'data')
	break;
      end
      fseek(file, len, SEEK_CUR);
    end

    if (formatid == 1)
      if bits == 8
      	sampleformat = 'uchar';
	precision = 'uchar';
        samples = len;
      elseif bits == 16
      	sampleformat = 'short';
	precision = 'short';
        samples = len/2;
      elseif bits == 32
	sampleformat = 'long';
	precision = 'long';
        samples = len/4;
      else
       	error(msg);
      endif
    elseif (formatid == 6 && bits == 8)
      sampleformat = 'alaw';
      precision = 'uchar';
      samples = len;
    elseif (formatid == 7 && bits == 8)
      sampleformat = 'ulaw';
      precision = 'uchar';
      samples = len;
    else
      error(msg);
      return;
    endif

  ## Sun .au format
  elseif strcmp(ext, 'au')

    ## Header format obtained from sox/au.c
    ## September 25, 1991
    ## Copyright 1991 Guido van Rossum And Sundry Contributors
    ## This source code is freely redistributable and may be used for
    ## any purpose.  This copyright notice must be maintained. 
    ## Guido van Rossum And Sundry Contributors are not responsible for 
    ## the consequences of using this software.

    str = setstr(fread(file, 4, 'char')');
    magic=' ds.';
    invmagic='ds. ';
    magic(1) = setstr(0);
    invmagic(1) = setstr(0);
    if strcmp(str, 'dns.') || strcmp(str, magic)
      arch = 'ieee-le';
    elseif strcmp(str, '.snd') || strcmp(str, invmagic)
      arch = 'ieee-be';
    else
      error(msg);
    end
    header = fread(file, 1, 'long', 0, 'ieee-be');
    len = fread(file, 1, 'long', 0, 'ieee-be');
    formatid = fread(file, 1, 'long', 0, 'ieee-be');
    rate = fread(file, 1, 'long', 0, 'ieee-be');
    channels = fread(file, 1, 'long', 0, 'ieee-be');
    fseek(file, header-24, SEEK_CUR); % skip file comment

    ## interpret the sample format
    if formatid == 1
      sampleformat = 'ulaw';
      precision = 'uchar';
      bits = 12;
      samples = len;
    elseif formatid == 2
      sampleformat = 'uchar';
      precision = 'uchar';
      bits = 8;
      samples = len;
    elseif formatid == 3
      sampleformat = 'short';
      precision = 'short';
      bits = 16;
      samples = len/2;
    elseif formatid == 5
      sampleformat = 'long';
      precision = 'long';
      bits = 32;
      samples = len/4;
    elseif formatid == 6
      sampleformat = 'float';
      precision = 'float';
      bits = 32;
      samples = len/4;
    elseif formatid == 7
      sampleformat = 'double';
      precision = 'double';
      bits = 64;
      samples = len/8;
    else
      error(msg);
    end
      
  ## Apple/SGI .aiff format
  elseif strcmp(ext,'aiff')

    ## Header format obtained from sox/aiff.c
    ## September 25, 1991
    ## Copyright 1991 Guido van Rossum And Sundry Contributors
    ## This source code is freely redistributable and may be used for
    ## any purpose.  This copyright notice must be maintained. 
    ## Guido van Rossum And Sundry Contributors are not responsible for 
    ## the consequences of using this software.
    ##
    ## IEEE 80-bit float I/O taken from
    ##        ftp://ftp.mathworks.com/pub/contrib/signal/osprey.tar
    ##        David K. Mellinger
    ##        dave@mbari.org
    ##        +1-831-775-1805
    ##        fax       -1620
    ##        Monterey Bay Aquarium Research Institute
    ##        7700 Sandholdt Road
 
    ## check the file magic header bytes
    arch = 'ieee-be';
    str = setstr(fread(file, 4, 'char')');
    if !strcmp(str, 'FORM')
      error(msg);
    end
    len = fread(file, 1, 'long', 0, arch);
    str = setstr(fread(file, 4, 'char')');
    if !strcmp(str, 'AIFF')
      error(msg);
    end

    ## skip to the "COMM" section, ignoring everything else
    while (1)
      if feof(file)
      	error(msg);
      end
      str = setstr(fread(file, 4, 'char')');
      len = fread(file, 1, 'long', 0, arch);
      if strcmp(str, 'COMM')
	break;
      end
      fseek(file, len, SEEK_CUR);
    end

    ## read the "COMM" section
    channels = fread(file, 1, 'short', 0, arch);
    frames = fread(file, 1, 'long', 0, arch);
    bits = fread(file, 1, 'short', 0, arch);
    exp = fread(file, 1, 'ushort', 0, arch);    % read a 10-byte float
    mant = fread(file, 2, 'ulong', 0, arch);
    mant = mant(1) / 2^31 + mant(2) / 2^63;
    if (exp >= 32768), mant = -mant; exp = exp - 32768; end
    exp = exp - 16383;
    rate = mant * 2^exp;
    fseek(file, len-18, SEEK_CUR);

    ## skip to the "SSND" section, ignoring everything else
    while (1)
      if feof(file)
      	error(msg);
      end
      str = setstr(fread(file, 4, 'char')');
      len = fread(file, 1, 'long', 0, arch);
      if strcmp(str, 'SSND')
	break;
      end
      fseek(file, len, SEEK_CUR);
    end
    offset = fread(file, 1, 'long', 0, arch);
    fread(file, 1, 'long', 0, arch);
    fseek(file, offset, SEEK_CUR);

    if bits == 8
      precision = 'uchar';
      sampleformat = 'uchar';
      samples = len - 8;
    elseif bits == 16
      precision = 'short';
      sampleformat = 'short';
      samples = (len - 8)/2;
    elseif bits == 32
      precision = 'long';
      sampleformat = 'long';
      samples = (len - 8)/4;
    else
      error(msg);
    endif
    
  ## file extension unknown
  else
    error('auload(filename.ext) understands .wav .au and .aiff only');
  end

  ## suck in all the samples
  if (samples <= 0) samples = Inf; end
  data = fread(file, samples, precision, 0, arch);
  fclose(file);

  ## convert samples into range [-1, 1)
  if strcmp(sampleformat, 'alaw')
    alaw = [ \
	     -5504,  -5248,  -6016,  -5760,  -4480,  -4224,  -4992,  -4736, \
	     -7552,  -7296,  -8064,  -7808,  -6528,  -6272,  -7040,  -6784, \
	     -2752,  -2624,  -3008,  -2880,  -2240,  -2112,  -2496,  -2368, \
	     -3776,  -3648,  -4032,  -3904,  -3264,  -3136,  -3520,  -3392, \
	    -22016, -20992, -24064, -23040, -17920, -16896, -19968, -18944, \
	    -30208, -29184, -32256, -31232, -26112, -25088, -28160, -27136, \
	    -11008, -10496, -12032, -11520,  -8960,  -8448,  -9984,  -9472, \
	    -15104, -14592, -16128, -15616, -13056, -12544, -14080, -13568, \
	      -344,   -328,   -376,   -360,   -280,   -264,   -312,   -296, \
	      -472,   -456,   -504,   -488,   -408,   -392,   -440,   -424, \
	       -88,    -72,   -120,   -104,    -24,     -8,    -56,    -40, \
	      -216,   -200,   -248,   -232,   -152,   -136,   -184,   -168, \
	     -1376,  -1312,  -1504,  -1440,  -1120,  -1056,  -1248,  -1184, \
	     -1888,  -1824,  -2016,  -1952,  -1632,  -1568,  -1760,  -1696, \
	      -688,   -656,   -752,   -720,   -560,   -528,   -624,   -592, \
	      -944,   -912,  -1008,   -976,   -816,   -784,   -880,   -848 ];
    alaw = [ alaw, -alaw]/32768;
    data = alaw(data+1);
  elseif strcmp(sampleformat, 'ulaw')
    data = mu2lin(data, 16)/32768;
  elseif strcmp(sampleformat, 'uchar')
    data = data/128 - 1;
  elseif strcmp(sampleformat, 'short')
    data = data/32768;
  elseif strcmp(sampleformat, 'long')
    data = data/2^31;
  end
  data = reshape(data, channels, length(data)/channels)';

endfunction

%!demo
%! [x, fs] = auload(file_in_loadpath("sample.wav"));
%! auplot(x,fs);
