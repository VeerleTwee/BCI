function [ label, EEG2, EEG, classInfo ] = applySSVEPclassifier_final(data,clssf,features,freq,EEG,hdr)
 
% applySSVEPclassifier :  It does the basic signal processing of the feedbcak acquired 
%                         signals and returns the prediction of the classifier 
% 
% => RETURNS: The prediction of the classifier 
% 
%   Detailed explanation goes here
%     freq : frequency band that you filter
%     channels =  channels of ROI
%     hdr : the data that we need from the buffer
%     data : the data from the calibration phase

    [EEG2]                      = SSVEP_sigPrePro_FEEDBACK_final(data,freq,EEG,hdr);
    [label,score,cost,var_mat]  = testSSVEPclassifier_final( EEG2, clssf, features ); % prediction of the classifier
    classInfo.label             = label;
    classInfo.score             = score;
    classInfo.cost              = cost;
    classInfo.var_mat           = var_mat;
end

