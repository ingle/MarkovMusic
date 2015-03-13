fileNames = {
    %'data_WAV/','Adana.wav';
    %'data_WAV/','AlhiyaBilawal.wav';
    %'data_WAV/','Bageshri.wav';
    %'data_WAV/','Basant.wav';
    %'data_WAV/','Behag.wav';
    %'data_WAV/','Bhoopali.wav';
    %'data_WAV/','Des.wav';
    %'data_WAV/','Durga.wav';
    %'data_WAV/','Hamir.wav';
    %'data_WAV/','Malkauns.wav';
    %'data_WAV/','TilakKamod.wav';
    %'data_WAV/','Todi.wav';
    'data_WAV/','b-fuga101.wav'
    };

for ff = 1:size(fileNames,1)
    dirFileNames = fileNames(ff,:);
    test_convert_audio_to_pitch;
    extract_midi_sequence;
    markov_music;
    markov2_music;
end
