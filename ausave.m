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

## usage: ausave('filename.ext', x, fs, format)
##
## Writes an audio file with the appropriate header. The extension on
## the filename determines the layout of the header. Currently supports
## .wav and .au layouts.  Data is a matrix of audio samples, one row
## time step, one column per channel. Fs defaults to 8000 Hz.  Format
## is one of ulaw, alaw, char, short, long, float, double
function ausave(path, data, rate, sampleformat)

  if nargin < 2 || nargin>4
    usage("ausave('filename.ext', x [, fs, sampleformat])");
  end
  if nargin < 3, rate = 8000; end
  if nargin < 4, sampleformat = 'short'; end

  ext = rindex(path, '.');
  if (ext == 0)
    usage("ausave('filename.ext', x [, fs, sampleformat])");
  end
  ext = tolower(substr(path, ext+1, length(path)-ext));

  [samples, channels] = size(data);

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

    if (strcmp(sampleformat,'uchar'))
      formatid = 1;
      samplesize = 1;
    elseif (strcmp(sampleformat,'short'))
      formatid = 1;
      samplesize = 2;
    elseif (strcmp(sampleformat, 'long'))
      formatid = 1;
      samplesize = 4;
    elseif (strcmp(sampleformat, 'alaw'))
      formatid = 6;
      samplesize = 1;
    elseif (strcmp(sampleformat, 'ulaw'))
      formatid = 7;
      samplesize = 1;
    else
      error("%s is invalid format for .wav file\n", sampleformat);
    end
    datasize = channels*samplesize*samples;

    [file, msg] = fopen(path, 'w');
    if (file == -1)
      error("%s: %s", msg, path);
    end

    ## write the magic header
    arch = 'ieee-le';
    fwrite(file, toascii('RIFF'), 'char');
    fwrite(file, datasize+36, 'long', 0, arch);
    fwrite(file, toascii('WAVE'), 'char');

    ## write the "fmt " section
    fwrite(file, toascii('fmt '), 'char');
    fwrite(file, 16, 'long', 0, arch);
    fwrite(file, formatid, 'short', 0, arch);
    fwrite(file, channels, 'short', 0, arch);
    fwrite(file, rate, 'long', 0, arch);
    fwrite(file, rate*channels*samplesize, 'long', 0, arch);
    fwrite(file, channels*samplesize, 'short', 0, arch);
    fwrite(file, samplesize*8, 'short', 0, arch);

    ## write the "data" section
    fwrite(file, toascii('data'), 'char');
    fwrite(file, datasize, 'long', 0, arch);

  ## Sun .au format
  elseif strcmp(ext, 'au')

    ## Header format obtained from sox/au.c
    ## September 25, 1991
    ## Copyright 1991 Guido van Rossum And Sundry Contributors
    ## This source code is freely redistributable and may be used for
    ## any purpose.  This copyright notice must be maintained. 
    ## Guido van Rossum And Sundry Contributors are not responsible for 
    ## the consequences of using this software.

    if (strcmp(sampleformat, 'ulaw'))
      formatid = 1;
      samplesize = 1;
    elseif (strcmp(sampleformat,'uchar'))
      formatid = 2;
      samplesize = 1;
    elseif (strcmp(sampleformat,'short'))
      formatid = 3;
      samplesize = 2;
    elseif (strcmp(sampleformat, 'long'))
      formatid = 5;
      samplesize = 4;
    elseif (strcmp(sampleformat, 'float'))
      formatid = 6;
      samplesize = 4;
    elseif (strcmp(sampleformat, 'double'))
      formatid = 7;
      samplesize = 8;
    else
      error("%s is invalid format for .au file\n", sampleformat);
    end
    datasize = channels*samplesize*samples;

    [file, msg] = fopen(path, 'w');
    if (file == -1)
      error("%s: %s", msg, path);
    end

    arch = 'ieee-be';
    fwrite(file, toascii('.snd'), 'char');
    fwrite(file, 24, 'long', 0, arch);
    fwrite(file, datasize, 'long', 0, arch);
    fwrite(file, formatid, 'long', 0, arch);
    fwrite(file, rate, 'long', 0, arch);
    fwrite(file, channels, 'long', 0, arch);

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

    if (strcmp(sampleformat,'uchar'))
      samplesize = 1;
    elseif (strcmp(sampleformat,'short'))
      samplesize = 2;
    elseif (strcmp(sampleformat, 'long'))
      samplesize = 4;
    else
      error("%s is invalid format for .aiff file\n", sampleformat);
    end
    datasize = channels*samplesize*samples;

    [file, msg] = fopen(path, 'w');
    if (file == -1)
      error("%s: %s", msg, path);
    end

    ## write the magic header
    arch = 'ieee-be';
    fwrite(file, toascii('FORM'), 'char');
    fwrite(file, datasize+46, 'long', 0, arch);
    fwrite(file, toascii('AIFF'), 'char');

    ## write the "COMM" section
    fwrite(file, toascii('COMM'), 'char');
    fwrite(file, 18, 'long', 0, arch);
    fwrite(file, channels, 'short', 0, arch);
    fwrite(file, samples, 'long', 0, arch);
    fwrite(file, 8*samplesize, 'short', 0, arch);
    fwrite(file, 16414, 'ushort', 0, arch);         % sample rate exponent
    fwrite(file, [rate, 0], 'ulong', 0, arch);       % sample rate mantissa

    ## write the "SSND" section
    fwrite(file, toascii('SSND'), 'char');
    fwrite(file, datasize+8, 'long', 0, arch); # section length
    fwrite(file, 0, 'long', 0, arch); # block size
    fwrite(file, 0, 'long', 0, arch); # offset

  ## file extension unknown
  else
    error('ausave(filename.ext,...) understands .wav .au and .aiff only');
  end

  ## convert samples from range [-1, 1)
  if strcmp(sampleformat, 'alaw')
    error("FIXME: ausave needs linear to alaw conversion\n");
    precision = 'uchar';
  elseif strcmp(sampleformat, 'ulaw')
    data = lin2mu(data);
    precision = 'uchar'
  elseif strcmp(sampleformat, 'uchar')
    data = data*128 + 128;
    precision = 'uchar';
  elseif strcmp(sampleformat, 'short')
    data = data*32768;
    precision = 'short';
  elseif strcmp(sampleformat, 'long')
    data = data*2^31;
    precision = 'long';
  else
    precision = sampleformat;
  end
  fwrite(file, data', precision, 0, arch);
  fclose(file);

endfunction
