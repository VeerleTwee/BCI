function [clssf , features ] = trainSSVEPclassifier_final(EEG)
%trainSSVEPclassifier: In this function we extract the features for the SSVEP stimuli using the 
%   Multivariate Linear Regression (MLR) technique that is proposed in
%    
%   Wang, H., Zhang, Y., Waytowich, N. R., Krusienski, D. J., Zhou, G., Jin, J., ... & Cichocki, A. (2016). 
%   "Discriminative feature extraction via multivariate linear regression for SSVEP-based BCI." 
%   IEEE Transactions on Neural Systems and Rehabilitation Engineering, 24(5), 532-541.
%   
%   After the feature extraction a knn classifier is trained.
%   The knn classifier is produced with the matlab function fitcknn
%   To see how it works type in the command window
% 
%   help fitcknn
% 
%   The characteristics that are used here are:
%                         - 'NumNeighbors'  = 2 
%                         - 'NSMethod'      = 'exhaustive'
%                         - Probability distribution of the stimuli 
%                           'Prior'         = [1 1 1 1 1 1] % equal probabilities all the classes
%                            If during the training there is trend for a
%                            class, then change the probabilities
%                            accordingly
%                        - 'ScoreTransform' = 'identity'
%                               
%   Input   : EEG structure with all the needed information
%   Outputs : 
%                 clssf    : trained knn classifier
%                 features : a structure that contains: 
%                                 features.train.x    = W_mlr'* train_Data;
%                                 The trained data
%                                 
%                                 features.train.y    = EEG.trainTargets';
%                                 the labels of the trained data
% 
%                                 features.train.W    = W_mlr;
%                                 The weights from the MLR
% 
%                                 features.train.pca  = PCA_W; 
%                                 the PCA coefficients that are needed to
%                                 map the  test features
% 
%                                 features.train.mu   = MeanTrainData; 
%                                 the mean values of the trained databecause
%                                 they are also needed for the
%                                 classification
% 
% 
%                                           

    %% FEATURE EXTRACTION OF THE TRAINING DATA
    [channels, samples, epochs]             = size(EEG.train);
    train_rawData                           = reshape(EEG.train, [samples*channels epochs]);
    MeanTrainData                           = mean(train_rawData, 2);
    train_rawData                           = train_rawData - repmat(MeanTrainData, 1, epochs);
    train_Y(max(EEG.trainTargets), epochs)  = 0;
    
    for ep = 1:epochs
         train_Y(EEG.trainTargets(ep),ep) = 1;
    end 
    %% EXTRACT THE WEIGHTS     
    PCA_W               = pca_func(train_rawData); 
    train_Data          = PCA_W'*train_rawData;
    train_Data          = [ones(1,epochs); train_Data];
    W_mlr               = MultiLR(train_Data, train_Y);
    features.train.x    = W_mlr'* train_Data;
    features.train.y    = EEG.trainTargets';
    features.train.W    = W_mlr;
    features.train.pca  = PCA_W;
    features.train.mu   = MeanTrainData;
    
%%   Train the k-nn classifier as is it used in the paper

    clssf = fitcknn(features.train.x',features.train.y,'NumNeighbors',2,...'KFold',10,...
       'NSMethod','exhaustive',...
        'Prior',[1 1 1 0.9 0.65 0.1],...%'uniform',... % [1 0.9 0.8 0.7 0.6 0.5]
        'ScoreTransform','identity'... %'doublelogit'
        );
end

