% Generate random music using a second order Markov chain model. We use a
% sliding window of size 2 to slide along the MIDI note sequence (suitably
% mapped to a set of integers {1,...,N}). Each pair of note
% occurence in the original sequency is assigned a state number. Hence we
% get another 1st order MC, but with number of states equal to
% N^2 (where N=numel(notesused)). The states in the second order markov
% chain that we embed to convert it to a first order markov chain are
% actually (1,1), (1,2), ..., (N,N).
%
% After mapping to a new state sequence {1,...,N^2} we estimate the
% transition matrix using this sequence as the input to hmmestimate.
% Finally, we do hmmgenerate and map the generated sequence back to the
% original state sequence by replacing each state number by its
% corresponding 2-tuple. Eg. 1->(1,1) and 2->(1,2) so 1,2 will map to 1,1,2
% of course maintaining the overlap with a sliding window.

% Map the midi sequence to a seq. of states {1, ..., numel(notesused)}
midistates = zeros(size(midiseq));
for ii=1:numel(notesused)
    midistates(midiseq == notesused(ii)) = ii;
end

% Embed this 2nd order chain output to a 1st order chain by pairing
N = numel(notesused);
secordstates = zeros(numel(midistates)-1,1);
for ptr = 2:numel(midistates)
   secordstates(ptr-1) = sub2ind([N,N], midistates(ptr-1), midistates(ptr)); % gets a linear Z^1 index for tuples from Z^2
end

% Now estimate transition matrix using secordstates
[trans2, emis2] = hmmestimate(secordstates, secordstates);
% emis is (hopefully) an identity matrix
if ~( ( sum(diag(emis2))==N^2 ) && (sum(emis2(:))-N^2 == 0) )
    disp('emis2 was not identity');
end

% Generate a random sequence using the transition matrix estimated above
[mkv_embed_states,~] = hmmgenerate(numel(secordstates), trans2, emis2);

% Reconstruct sequence of the original second order MC states by unraveling
% the pairs
mkv2states = zeros(numel(mkv_embed_states)+1,1);
for ii=1:numel(mkv_embed_states)
    [rw,cl] = ind2sub([N,N], mkv_embed_states(ii));
    mkv2states(ii) = rw; mkv2states(ii+1) = cl;
end

% Map back to actual MIDI note numbers
mkv2seq = zeros(size(mkv2states));
for ii=1:numel(notesused)
   mkv2seq(mkv2states==ii) = notesused(ii); 
end


% Transform mkv2seq to a new datastructure (curnote, sample-dur) sequence.
%mkv2seq = midiseq;
audiostruct = [];
ptr = 1; idx = Inf;
runlenghts = zeros(size(notesused));
while ~isempty(idx)
    idx = find(mkv2seq(ptr:end)~=mkv2seq(ptr), 1, 'first');
    if ~isempty(idx)
        audiostruct = [audiostruct; mkv2seq(ptr), idx-1];
        ptr = ptr + idx - 1;
    else
        audiostruct = [audiostruct; mkv2seq(ptr), numel(mkv2seq)-ptr+1];
    end
end

% Now play the mkv2seq, at specified sampling rate
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
wavwrite(fullsong, 22050, ['Markov2/markov2music_',dirFileNames{2}]);