clear
clc
close all

if ismac; use_bracket = '/'; else use_bracket = '\'; end;
addpath(genpath([pwd use_bracket 'functions']))
addpath(genpath([pwd use_bracket 'DatasetFiles']))

%%%% choose database to apply NARX-QoE

%%%%%% LIVE_NFLX
db_test = 'LIVE_NFLX';
feats_all = {{'quality', 'Nrebuffers', 'TSL'}};
load('LIVE_NFLX_Network_Impairments.mat');
load('TrainingTestingContinuousData.mat');
%%%%%% LIVE STALL II
db_test = 'Stall_DB';
feats_all = {{'Nrebuffers', 'TSL'}};
%%%%%% LIVE_HTTP
db_test = 'LIVE_HTTP_DB';
feats_all = {{'quality'}};

db_train = db_test;

%%%% set input and external variable lags
IDs = {0:10};
FDs = {1:10};

%%%% set number of hidden nodes in hidden layer
Hs = {8};

%%%% set other related parameters
quality_models = {{'STRRED'}};
training_in_closed_loop = false;
N_inner_trials = 1;
train_func = 'trainlm';
divide_fcn = 'divideblock';
trainRatio = 0.80;
valRatio = 0.20;
testRatio = 0;
epochs_narx = 200;

%%%% get randomized test indices and then pick the first for demo purposes
test_inds = get_test_inds(db_test);
test_inds = test_inds(1);

%%%% repeat for all test indices
for n_trial = 1 : length(test_inds)
    
    test_ind = test_inds(n_trial);
    if strcmp(db_test, 'LIVE_NFLX'); disp([db_test ', ' num2str(LIVE_NFLX_Network_Impairments{test_ind, 1})]);
    else disp([db_test ', test video: ' num2str(test_ind)]);
    end;
    
    feats_ind = 0;
    
    %%%% repeat for all feature combinations
    for feats = feats_all
        
        feats_ind  = feats_ind + 1;
        
        %%%% repeat for all possible quality models (for now showing only ST-RRED)
        for quality_model = quality_models
            
            %%%% get train indices for this particular test index
            [train_inds, only_qual, Train_Matrix_FeedIn] = get_train_inds(db_train, db_test, ...
                test_ind, ...
                TrainingMatrix_LIVENetflix_Continuous_MdlSel, ...
                TrainingMatrix_LIVENetflix_Continuous);
            
            %%%% get exogenous variables, like VQA
            [EXOG_train, input_subj_train, input_subj_ALL_train, ...
                EXOG_test, input_subj_test, input_subj_ALL_test] = ...
                get_EXOG(db_train, db_test, ...
                quality_model, feats);
            
            disp(['Training with: ' num2str(length(train_inds)) ' videos'])
            disp(['Testing: ' num2str(length(test_ind)) ' video(s)'])
            
            if training_in_closed_loop
                training_in_closed_loop_now = true;
            else
                training_in_closed_loop_now = false;
            end;
            
            %%%% train and test the predictor
            [NARX_preds, NARX_gts] = apply_NARX(training_in_closed_loop_now, IDs, FDs, Hs, ...
                train_inds, test_ind, input_subj_train, input_subj_test, ...
                N_inner_trials, train_func, ...
                divide_fcn, trainRatio, valRatio, testRatio, epochs_narx, ...
                EXOG_train, EXOG_test);
            
        end;
        
    end;
    
end;


fnt_sz = 20;

%%%% show results
%%%% note: output may not be as good for some testcases
%%%% you can try adding more features, re-running the network with
%%%% different initial weights or setup a different architecture
figure
plot(NARX_preds{1}, 'r', 'LineWidth', 2.5)
hold on
plot(NARX_gts{1}, 'b', 'LineWidth', 2.5)
grid
h = legend('NARX', 'Ground Truth', 'Location', 'SouthWest');
h.FontWeight = 'bold';
h.FontSize = 15;
xlabel('Sample #', 'fontweight', 'bold', 'FontSize', fnt_sz)
ylabel('QoE', 'fontweight', 'bold', 'FontSize', fnt_sz)

