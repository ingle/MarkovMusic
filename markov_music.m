% This estimates the 1st order Markov chain transition matrix from a sample
% state sequence, where the states are Midi notes
% It then generates a random sequence using this estimated transition
% matrix and plays the audio
% % %

% Map the midi sequence to a seq. of states {1, ..., numel(notesused)}
midistates = zeros(size(midiseq));
for ii=1:numel(notesused)
    midistates(midiseq == notesused(ii)) = ii;
end

[trans, emis] = hmmestimate(midistates, midistates);
% emis is (hopefully) an identity matrix
if ~( ( sum(diag(emis))==numel(notesused) ) && (sum(emis(:))-numel(notesused) == 0) )
    disp('emis was not identity');
end

[mkvstates,~] = hmmgenerate(numel(midiseq), trans, emis);

mkvseq = zeros(size(mkvstates));
for ii=1:numel(notesused)
   mkvseq(mkvstates==ii) = notesused(ii); 
end

% Transform mkvseq to a new datastructure (curnote, sample-dur) sequence.
%mkvseq = midiseq;
audiostruct = [];
ptr = 1; idx = Inf;
runlenghts = zeros(size(notesused));
while ~isempty(idx)
    idx = find(mkvseq(ptr:end)~=mkvseq(ptr), 1, 'first');
    if ~isempty(idx)
        audiostruct = [audiostruct; mkvseq(ptr), idx-1];
        ptr = ptr + idx - 1;
    else
        audiostruct = [audiostruct; mkvseq(ptr), numel(mkvseq)-ptr+1];
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

% Now play the mkvseq, at specified sampling rate
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
wavwrite(fullsong, 22050, ['Markov/markovmusic_',dirFileNames{2}]);