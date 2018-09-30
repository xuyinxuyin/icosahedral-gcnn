setup(true,struct('enableGpu',true,'cudaMethod','nvcc'));
res_ip1=randn(12,1,2,1);
res_ip2=randn(12,1,2,1);
res_i=randn(12,1,4,1);
weights=cell(2,1);
weights{1}=randn(12,1,4,2);
weights{2}=zeros(2,1);
invv=finv();
mat=mulalter();

res_i2=res_i(mat(6,:),:,:,:);
matt=zeros(size(mat));
for i=1:12
     ind=mat(:,i);
     ind=ind(invv);
    matt(:,i)=ind;
 end
 group_index=matt;
 CU={'CuDNN'};
for i=1:12
res_ip1(i,:,:,:)=vl_nnconv(res_i,weights{1}(group_index(:,i)',:,:,:),weights{2}, ...
        'pad', 0, ...
        'stride', 1, ...
        CU{:});
res_ip2(i,:,:,:)=vl_nnconv(res_i2,weights{1}(group_index(:,i)',:,:,:),weights{2}, ...
        'pad', 0, ...
        'stride', 1, ...
        CU{:});
end
res_ip1(mat(6,:),:,:,:)-res_ip2


    



