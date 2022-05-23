function [markers_aligned, markers] = alignDannceNF(pred)
markers = pred;

spine2 = markers(:,:,4);
spine3 = markers(:,:,6);

fprintf('rotating markers \n')
rotangle = atan2(-(spine2(:,2)-spine3(:,2)),...
    (spine2(:,1)-spine3(:,1)));
global_rotmatrix = zeros(2,2,numel(rotangle));
global_rotmatrix(1,1,:) = cos(rotangle);
global_rotmatrix(1,2,:) = -sin(rotangle);
global_rotmatrix(2,1,:) = sin(rotangle);
global_rotmatrix(2,2,:) = cos(rotangle);

cluster_mean_array =  squeeze(markers(:,:,5));
markers_aligned = zeros(size(markers));

for i = 1:23
    markers_aligned(:,:,i) = bsxfun(@minus,markers(:,:,i),cluster_mean_array);
end
for i = 1:23
   for N = 1:length(markers_aligned)
        markers_aligned(N,1:2,i) = global_rotmatrix(:,:,N)*reshape(markers_aligned(N,1:2,i),2,1,[]);
   end
end