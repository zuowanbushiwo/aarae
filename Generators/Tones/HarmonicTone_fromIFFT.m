function [OUT, varargout] = HarmonicTone_fromIFFT(fs, duration, f0, phase, slope)
% This function generates a harmonic tone in the frequency domain, and
% generates the waveform via inverse fast Fourier transform. The
% fundamental frequency of the wave is adjusted to the nearest Fourier
% component. The minimum length of the IFFT is 10 s, meaning that frequency
% resolution should be to 0.1 Hz (or better for long duration waves).
%
% The DC or 0 Hz component is not generated by this function.
%
% Spectral magnitude slope does not refer to the magnitude slope from
% harmonic to harmonic, but instead refers to the slope of the summed
% harmonics from octave to octave. Use +3 dB/oct if you wish all of the 
% harmonics to have the same magnitude.
%
% Code by Densil Cabrera
% Version 1.00 (29 December 2013)

if nargin == 0
    
    param = inputdlg({'Audio sampling rate (Hz)';...
        'Tone duration (s)';...
        'Fundamental frequency (Hz)';...
        'Phase in degrees, or -1 for random phase';...
        'Spectral magnitude slope (dB/octave)'},...
        'Settings',...
        [1 60],...
        {'48000';'1';'1';'-1';'0'}); % default values
    
    param = str2num(char(param));
    
    if length(param) < 5, param = []; end
    if ~isempty(param)
        fs = param(1);
        duration = param(2);
        f0 = param(3);
        phase = param(4);
        slope = param(5);
    end
else
    param = [];
end


if ~isempty(param) || nargin ~= 0
    
    % DETERMINE THE NUMBER OF SAMPLES TO GENERATE
    if duration >= 10
        ifftlen = duration*fs;
    else
        ifftlen = fs*10; % minimum spectrumlength, gives 0.1 Hz resolution
    end
    
    if rem(ifftlen,2)==1
        ifftlen = ifftlen+1; % even number of samples
    end
    
    
    % CREATE THE SPECTRUM BELOW NYQUIST FREQUENCY
    f0comp = round(f0 * ifftlen / fs); %index for f0, not incl 0 Hz
    halfspectrum = zeros(ifftlen/2-1,1); % half spectrum, not incl 0 Hz
    halfspectrum(f0comp:f0comp:end) = 1; % fundamental and all harmonics =1
    fexponent = (slope-3)/3;
    
    % magnitude slope function (for half spectrum, not including DC and
    % Nyquist)
    magslope = ((1:ifftlen/2-1)./(ifftlen/4)).^(fexponent*0.5)';
    
    % slope for inverse filter
    %magslope2 = ((1:nsamples/2-1)./(nsamples/4)).^(-fexponent*0.5)';
    
    % apply spectral slope
    halfspectrum = halfspectrum.*magslope;
    
    if phase >= 0
        phaseval = pi*phase/180;
    else
        phaseval = rand(ifftlen/2-1,1)*2*pi;
    end
    halfspectrum = halfspectrum .* exp(1i.*phaseval);
    
    % GENERATE WAVEFORM VIA IFFT
    audio = ifft([zeros(1,1);halfspectrum;zeros(1,1);flipud(conj(halfspectrum))]);
    
    % truncate if required
    if length(audio) > duration*fs
        audio = audio(1:duration*fs);
    end
    
    % normalize
    audio = audio ./ max(abs(audio));
    
    if nargin == 0
        OUT.audio = audio;
        %OUT.audio2 = ?;
        OUT.fs = fs;
        OUT.tag = [num2str(f0),'Hz HarmonicTone'];
        OUT.funcallback.name = 'HarmonicTone_fromIFFT.m';
        OUT.funcallback.inarg = {fs, duration, f0, phase, slope};
    end
    
    
    if nargin ~= 0
        OUT = audio;
        varargout{1} = fs;
        
    end
else
    
    OUT = [];
end

end % End of function

%**************************************************************************
% Copyright (c) 2013, Densil Cabrera
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%  * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%  * Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%  * Neither the name of the University of Sydney nor the names of its contributors
%    may be used to endorse or promote products derived from this software
%    without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
% OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%**************************************************************************