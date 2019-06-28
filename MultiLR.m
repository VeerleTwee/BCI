function W_mlr = MultiLR(train_Feat,train_Y)
% created 03-26-2017
% Okba Bekhelifi, <okba.bekhelif@univ-usto.dz>
% 
% The approach is based on the following publiction: 
%
% Wang, H., Zhang, Y., Waytowich, N. R., Krusienski, D. J., Zhou, G., Jin, J., ... & Cichocki, A. (2016). 
% "Discriminative feature extraction via multivariate linear regression for SSVEP-based BCI." 
% IEEE Transactions on Neural Systems and Rehabilitation Engineering, 24(5), 532-541.

% Multiple linear regression
% train_Feat: training samples
% train_Y: label matrix

    [U,Sigma,V] = svd(train_Feat,'econ');
    r           = rank(Sigma);
    U1          = U(:,1:r);
    V1          = V(:,1:r);
    Sigma_r     = diag(Sigma(1:r, 1:r));        
    W_mlr       = U1*diag(1./Sigma_r)*V1'*train_Y';
    
end