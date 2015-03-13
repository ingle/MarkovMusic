% Extract note sequence from the f_pitch matrix
% The sequence will be a sequence of MIDI note numbers for each time
% instant. An empty time bin is ignored. This is because the Markov chain
% transitions must be trained for notes and not going from note to silence
% and silence to note.
%
% If two notes overlap in time, the one with higher amplitude will be
% assumed to be playing.

% eg. output could be [78 78  80 80 80 80 80 79 79]
% The sampling rate will decide how long each note is sustained in time.

PEAKTHRESH = 0.02;

pitchmat = f_pitch;

%midiseq = 999*ones(size(f_pitch,2), 1); %currently all blank

midiseq = [];

for col = 1:size(f_pitch,2) % in each col, i.e. time instant
    %disp([num2str(col),'/',num2str(size(f_pitch,2))]);
    timeslice = f_pitch(:,col);
    idx = (timeslice > PEAKTHRESH);
    if sum(idx)==0
        continue;
    end
    maxidx = (timeslice.*idx==max(timeslice.*idx));
    maxidx = find(maxidx==1, 1, 'first');
    midiseq = [midiseq; maxidx];
end

notesused = unique(midiseq);
timesused = zeros(size(notesused));
for ii=1:numel(notesused)
    timesused(ii) = sum(midiseq==notesused(ii));
end

% Now write the extracted midiseq to a a wav file so we can compare all
% audio as monophonic recordings

audiostruct = [];
ptr = 1; idx = Inf;
runlenghts = zeros(size(notesused));
while ~isempty(idx)
    idx = find(midiseq(ptr:end)~=midiseq(ptr), 1, 'first');
    if ~isempty(idx)
        audiostruct = [audiostruct; midiseq(ptr), idx-1];
        ptr = ptr + idx - 1;
    else
        audiostruct = [audiostruct; midiseq(ptr), numel(midiseq)-ptr+1];
    end
end

% Remove all blank spaces now by sustaining the previous note
%{
for ii = 2:size(audiostruct,1)
    if audiostruct(ii,1)==999
        audiostruct(ii,1)=audiostruct(ii-1,1);
    end
end
%}

% Now save the midiseq, at specified sampling rate
fullsong = [];
fs = 22050;
for ijk = 1:size(audiostruct,1)
    if audiostruct(ijk,1)~=999 && audiostruct(ijk,2)>10
        [~,~,wf] = playmidinote(audiostruct(ijk,1), 2*audiostruct(ijk,2)*1328358/10379/22050);
        %[~,~,wf] = playmidinote(audiostruct(ijk,1), 50*1328358/10379/22050);
        fullsong = [fullsong; wf];
    else
        %[~,~,wf] = playmidinote(1, 2*audiostruct(ijk, 2)*1328358/10379/22050);
        % basically this means silence (very low freq, you can't hear)
        %fullsong = [fullsong; wf];
    end
end
%}
wavwrite(fullsong, 22050, ['Orig/music_',dirFileNames{2}]);