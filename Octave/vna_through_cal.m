% VNA 2018 VNA test script.
% Rob Frohne, May 2017.
% This script will make nFreq measurements from fMin to fMax.
% It is designed to make S21 measurements and use calibration.
% The first step is to connect your cables together, and do a
% a through calibration measurement.  Then you can measure the DUT.
% It will divide out the transfer function of the cables, so they
% don't mess up your measurement of the DUT.

clc; clear;
close all;

fMin = 1.e6;
fMax = 100.e6;
nFreq = 100;

% Load the package
pkg load instrument-control
% Check if serial support exists
if (exist("serial") != 3)
  disp("No Serial Support");
endif
% Instantiate the Serial Port
% Naturally, set the COM port # to match your device
% Use this crazy notation for any COM port number: 1 - 255
%s1 = serial("/dev/pts/2");
%s1 = serial("/tmp/ttyDUMMY"); % $ interceptty /dev/ttyACM0 /tmp/ttyDUMMY
s1 = serial("/dev/ttyACM0");
pause(1); % Wait a second as it takes some ports a while to wake up
% Set the port parameters
set(s1,'baudrate', 115200);
set(s1,'bytesize', 8);
set(s1,'parity', 'n');
set(s1,'stopbits', 1);
set(s1,'timeout', 255); % 12.3 Seconds as an example here
% Optional commands, these can be 'on' or 'off'
%set(s1, 'requesttosend', 'on');
 % Sets the RTS line
%set(s1, 'dataterminalready', 'on'); % Sets the DTR line
disp("Connect the through connection and hit return.")
pause;
% Optional - Flush input and output buffers
srl_flush(s1);
string_to_send = strcat("^SWEEP,",num2str(uint64(fMin)),","...
                  ,num2str(uint64(fMax)),",",num2str(uint64(nFreq)),"$\n")
srl_write(s1,string_to_send);
for i=1:nFreq
  raw(i,:) = str2num(ReadToTermination(s1, 10));
  if(mod(i,10) == 0) 
    disp(i)
  endif
endfor
for i=1:nFreq
  H1thru(i) = (raw(i,1)+j*raw(i,2))./(raw(i,3)+j*raw(i,4));
endfor
disp("Now connect your DUT, and push return.")
pause;
srl_flush(s1);
string_to_send = strcat("^SWEEP,",num2str(uint64(fMin)),","...
                  ,num2str(uint64(fMax)),",",num2str(uint64(nFreq)),"$\n")
srl_write(s1,string_to_send);
for i=1:nFreq
  raw(i,:) = str2num(ReadToTermination(s1, 10));
  if(mod(i,10) == 0) 
    disp(i)
  endif
endfor
for i=1:nFreq
  H1comb(i) = (raw(i,1)+j*raw(i,2))./(raw(i,3)+j*raw(i,4));
endfor
H1dut = H1comb./H1thru;
% Assume this is for S21.
figure(1)
df = (fMax-fMin)/nFreq;
f=fMin:df:fMax-df;
plot(f,20*log10(abs(H1dut)),'bo')
xlabel('Frequency (Hz)')
title('|S_{21}|')
ylabel('(dB)')
figure(2)
plot(f,angle(H1dut)*180/pi,'bo')
xlabel('Frequency (Hz)')
title('Angle of S_{21}')
ylabel('(degrees)')
% Finally, Close the port
fclose(s1);