function [ label,score,cost,var_mat] = testSSVEPclassifier_final( EEG2, clssf, features )
%testSSVEPclassifier: In this function we extract the features for the SSVEP stimuli using the 
%   Multivariate Linear Regression (MLR) technique that is proposed in
%    
%   Wang, H., Zhang, Y., Waytowich, N. R., Krusienski, D. J., Zhou, G., Jin, J., ... & Cichocki, A. (2016). 
%   "Discriminative feature extraction via multivariate linear regression for SSVEP-based BCI." 
%   IEEE Transactions on Neural Systems and Rehabilitation Engineering, 24(5), 532-541.
% 
%   Input   :  EEG structure, the trained classifier, the needed features
%   Outputs :  label : predicted class
% 
%                                        

    [channels, samples, epochs] = size(EEG2.test);
    test_rawData                = reshape(EEG2.test, [samples*channels epochs]);
    test_rawData                = test_rawData - repmat(features.train.mu, 1, 1);
    test_Data                   = features.train.pca'*test_rawData; % map the testing data
    test_Data                   = [ones(1,epochs);test_Data];
    features.test.x             = features.train.W'*test_Data; 
    var_mat                     = var(features.test.x); % variation of the features we may use it to not predict anything
    [label,score,cost]          = predict(clssf,features.test.x');

end

