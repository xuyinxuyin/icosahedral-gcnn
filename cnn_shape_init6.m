function net = cnn_shape_init6(classNames, varargin)
opts.base = 'imagenet-matconvnet-vgg-m'; 
opts.restart = false; 
opts.nViews =12; 
opts.viewpoolPos = 'conv5';  
opts.weightInitMethod = 'xavierimproved';
opts.scale = 1;
opts.networkType = 'simplenn'; % only simplenn is supported currently
opts = vl_argparse(opts, varargin); 
opts.sub_fxLocation='conv5';
opts.sub_fxType='max';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
invv=finv();
mat=mulalter();
 for i=1:60
     ind=mat(:,i);
     ind=ind(invv);
     mat(:,i)=ind;
 end
opts.groupindex=mat;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opts.finalpoolType='max';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


assert(strcmp(opts.networkType,'simplenn'), 'Only simplenn is supported currently'); 

init_bias = 0.1;
nClass = length(classNames);

% Load model, try to download it if not readily available
if ~ischar(opts.base), 
  net = opts.base; 
else
  netFilePath = fullfile('data','models', [opts.base '.mat']);
  if ~exist(netFilePath,'file'),
    fprintf('Downloading model (%s) ...', opts.base) ;
    vl_xmkdir(fullfile('data','models')) ;
    urlwrite(fullfile('http://www.vlfeat.org/matconvnet/models/', ...
      [opts.base '.mat']), netFilePath) ;
    fprintf(' done!\n');
  end
  net = load(netFilePath);
end

assert(strcmp(net.layers{end}.type, 'softmax'), 'Wrong network format'); 
dataTyp = class(net.layers{end-1}.weights{1}); 
% Initiate the last but one layer w/ random weights
widthPrev = size(net.layers{end-1}.weights{1}, 3);
nClass0 = size(net.layers{end-1}.weights{1},4);
if nClass0 ~= nClass || opts.restart, 
  net.layers{end-1}.weights{1} = init_weight(opts, 1, 1, widthPrev, nClass, dataTyp);
  net.layers{end-1}.weights{2} = zeros(nClass, 1, dataTyp); 
end

% Initiate other layers w/ random weights if training from scratch is desired
if opts.restart, 
  w_layers = find(cellfun(@(c) isfield(c,'weights'),net.layers));
  for i=w_layers(1:end-1), 
    sz = size(net.layers{i}.weights{1}); 
    net.layers{i}.weights{1} = init_weight(opts, sz(1), sz(2), sz(3), sz(4), dataTyp);
    net.layers{i}.weights{2} = zeros(sz(4), 1, dataTyp); 
  end	
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if opts.nViews==1
%remove pool5 layer
if ~strcmp(opts.sub_fxLocation,'pool5')
loc = find(cellfun(@(c) strcmp(c.name,'pool5'), net.layers));
net=modify_net(net,net.layers{loc}, ...
        'mode','rm_layer', ...
        'loc',net.layers{loc}.name);
end



%add sub_fx layer
sub_fxLayer= struct('name', 'pool5', ...
    'type', 'pool', ...
    'method', opts.sub_fxType, ...
    'pool',[13,13],...
    'pad',0,...
    'stride',1,...
    'opts',{{}},...
    'weights',{{}},...
    'precious',0);
net = modify_net(net, sub_fxLayer, ...
        'mode','add_layer', ...
        'loc',opts.sub_fxLocation);
%change fc6
loc = find(cellfun(@(c) strcmp(c.name,'fc6'), net.layers));
sz=size(net.layers{loc}.weights{1});
net.layers{loc}.weights{1}=init_weight(opts, 1, 1, sz(3), sz(4), dataTyp);
net.layers{loc}.weights{2}=zeros(sz(4),1,dataTyp);

%remove fc7
loc= find(cellfun(@(c) strcmp(c.name,'fc7'), net.layers));
net=modify_net(net,net.layers{loc}, ...
        'mode','rm_layer', ...
        'loc',net.layers{loc}.name);
end      

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Swap softmax w/ softmaxloss
net.layers{end} = struct('type', 'softmaxloss', 'name', 'loss') ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%instert finalpoolLayer
if opts.nViews>1,
    finalpoolLayer=struct('name', 'finalpool', ...
    'type', 'custom', ...
    'vstride', opts.nViews, ...
    'method', opts.finalpoolType, ...
    'forward', @finalpool_fw, ...
    'backward', @finalpool_bw,...
     'precious',0);
  net = modify_net(net, finalpoolLayer, ...
        'mode','add_layer', ...
        'loc',net.layers{end-1}.name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Insert viewpooling
  viewpoolLayer = struct('name', 'viewpool', ...
    'type', 'custom', ...
    'vstride', opts.nViews, ...
    'forward', @viewpool_fw, ...
    'backward', @viewpool_bw,...
    'precious',0);
  net = modify_net(net, viewpoolLayer, ...
        'mode','add_layer', ...
        'loc',opts.viewpoolPos);
%take out the pooling layers that is behind the viewpool layer 
loc = find(cellfun(@(c) strcmp(c.name,'viewpool'), net.layers));
pool_layers = find(cellfun(@(s) strcmp(s.name(1:2),'po'),net.layers));
pol_ind=arrayfun(@(s) s>loc, pool_layers);
pool_layers=pool_layers(pol_ind);
for pol_ind=1:length(pool_layers)
      net=modify_net(net,net.layers{pool_layers(pol_ind)}, ...
        'mode','rm_layer', ...
        'loc',net.layers{pool_layers(pol_ind)}.name);
end
loc = find(cellfun(@(c) strcmp(c.name,'relu6'), net.layers));
 net=modify_net(net,net.layers{loc}, ...
        'mode','rm_layer', ...
        'loc',net.layers{loc}.name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%modify the layers betweent the viewpool layer and finalpool layer
loc = find(cellfun(@(c) strcmp(c.name,'viewpool'), net.layers));
weight_layer=find(cellfun(@(c) isfield(c,'weights')&&~isempty(c.weights), net.layers));
modify_index=arrayfun(@(s) s>loc,weight_layer);
modify_layer=weight_layer(modify_index);
for innd=1:length(modify_layer)
    [~,~,s3,s4]=size(net.layers{modify_layer(innd)}.weights{1});
    weights=cell(1,2);
       weights{1}=cat(1,net.layers{modify_layer(innd)}.weights{1},zeros(opts.nViews-1,1,s3,s4));
       weights{2}=zeros(s4,1,dataTyp);
      
  %learningRate= net.layers{modify_layer(innd)}.learningRate;
  weightDecay= net.layers{modify_layer(innd)}.weightDecay;
    net.layers{modify_layer(innd)}=struct('name',['group_conv',num2str(innd)],...
        'type','custom',...
        'groupindex',opts.groupindex,...
        'forward', @groupconv_fw, ...
    'backward', @groupconv_bw,...
    'weights',{weights},...
    'accumulate',false,...
    'cudnn',{{'CuDNN'}},...
    'precious',0,...
     'learningRate',[1,2],...
     'opts',{{}},...
      'weightDecay',weightDecay); 
end



end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update meta data


net.meta.classes.name = classNames;
net.meta.classes.description = classNames;

% speial case: when no class names specified, remove fc8/prob layers
if nClass==0, 
    net.layers = net.layers(1:end-2);
end
    

end

% -------------------------------------------------------------------------
function weights = init_weight(opts, h, w, in, out, type)
% -------------------------------------------------------------------------
% See K. He, X. Zhang, S. Ren, and J. Sun. Delving deep into
% rectifiers: Surpassing human-level performance on imagenet
% classification. CoRR, (arXiv:1502.01852v1), 2015.
switch lower(opts.weightInitMethod)
  case 'gaussian'
    sc = 0.01/opts.scale ;
    weights = randn(h, w, in, out, type)*sc;
  case 'xavier'
    sc = sqrt(3/(h*w*in)) ;
    weights = (rand(h, w, in, out, type)*2 - 1)*sc ;
  case 'xavierimproved'
    sc = sqrt(2/(h*w*out)) ;
    weights = randn(h, w, in, out, type)*sc ;
  otherwise
    error('Unknown weight initialization method''%s''', opts.weightInitMethod) ;
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------------------------------------------------------------------------
function res_ip1 = finalpool_fw(layer, res_i, res_ip1)
% -------------------------------------------------------------------------
if strcmp(layer.method, 'avg'), 
    res_ip1.x =mean(res_i.x,1);
elseif strcmp(layer.method, 'max'), 
    res_ip1.x =max(res_i.x,[],1);
else
    error('Unknown viewpool method: %s', layer.method);
end
%    res_i.x(:,:,1,1)
%    res_ip1.x(:,:,1,1)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -------------------------------------------------------------------------
function res_i = finalpool_bw(layer, res_i, res_ip1)
% -------------------------------------------------------------------------
[sz1, sz2, sz3, sz4] = size(res_ip1.dzdx);
if strcmp(layer.method, 'avg')
%     res_i.dzdx =reshape(repmat(reshape(res.ip1.dzdx,[sz1,sz2*sz3*sz4]),[sz1*layer.vstride,1,1,1]),...
%         [sz1*layer.vstride,sz2,sz3,sz4]);
      res_i.dzdx=repmat(res_ip1.dzdx,[layer.vstride,1,1,1])/layer.vstride;
elseif strcmp(layer.method, 'max') 
        [~,I]=max(reshape(res_i.x,[sz1*layer.vstride,sz2*sz3*sz4]),[],1);
         Ind=zeros(sz1*layer.vstride,sz2*sz3*sz4);
         Ind(sub2ind(size(Ind),I,1:length(I))) = 1; 
         res_i.dzdx =reshape(repmat(reshape(res_ip1.dzdx,[sz1,sz2*sz3*sz4]),[layer.vstride,1]),...
         [sz1*layer.vstride,sz2,sz3,sz4]).*reshape(Ind,[sz1*layer.vstride,sz2,sz3,sz4]); 
        
else
    error('Unknown viewpool method: %s', layer.method);
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
function res_ip1 = viewpool_fw(layer, res_i, res_ip1)
% -------------------------------------------------------------------------
% [~, ~, sz3, sz4] = size(res_i.x);
% if strcmp(layer.method, 'avg')
%   middle=mean(mean(res_i.x,2),1);
%    res_ip1.x=reshape(permute(reshape(middle,[1,1,sz3,layer.vstride,sz4/layer.vstride]),[4,2,1,3,5]),...
%     [layer.vstride,1,sz3,sz4/layer.vstride]);
% elseif strcmp(layer.method, 'max') 
%    middle=max(max(res_i.x,[],2),[],1);
%    res_ip1.x=reshape(permute(reshape(middle,[1,1,sz3,layer.vstride,sz4/layer.vstride]),[4,2,1,3,5]),...
%     [layer.vstride,1,sz3,sz4/layer.vstride]);
% else
%   error('Unknown viewpool method: %s', layer.method);
% end
szi=size(res_i.x);
res_ip1.x=reshape(permute(reshape(res_i.x,[1,1,szi(3),layer.vstride,szi(4)/layer.vstride]),...
    [4,1,2,3,5]),[layer.vstride,1,szi(3),szi(4)/layer.vstride]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% -------------------------------------------------------------------------
function res_i = viewpool_bw(layer, res_i, res_ip1)
% -------------------------------------------------------------------------
szi=size(res_i.x);
res_i.dzdx=reshape(permute(reshape(res_ip1.dzdx,[layer.vstride,1,1,szi(3),szi(4)/layer.vstride]),[2,3,4,1,5]),[1,1,szi(3),szi(4)]);
                                                                                                                                    %%%still have problems
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function res_ip1=groupconv_fw(layer, res_i, res_ip1)
       [s1,s2,~,s4]=size(res_i.x);
       s3=size(layer.weights{2},1);
       res_ip1.x=gpuArray(single(zeros(s1,s2,s3,s4)));
       group_index=layer.groupindex;
       for i=1:60
       res_ip1.x(i,:,:,:) = vl_nnconv(res_i.x,layer.weights{1}(group_index(:,i)',:,:,:),layer.weights{2}, ...
        'pad', 0, ...
        'stride', 1, ...
        layer.opts{:}, ...
        layer.cudnn{:}); 
       end
      
 
%      if strcmp(layer.name,'group_conv1')
%         disp('group_conv1')
%          res_i.x(:,:,1,1)
%          res_ip1.x(:,:,1,1)
%          layer.weights{1}(:,:,1,1)
%       end  
%     
%    if strcmp(layer.name,'group_conv2')
%        disp('group_conv2')
%        res_i.x(:,1,1,1)
%        max(res_ip1.x(:,1,1,1))
%        max(res_ip1.x(:,1,2,1))
%        max(res_ip1.x(:,1,3,1))
%        layer.weights{1}(:,1,1,1)
%        
%     end  
%     
%      if strcmp(layer.name,'group_conv3')
%        disp('group_conv3')
%        var(res_i.x(:))
%        var(res_ip1.x(:))
%     end  
    
    
    end
    

    function res_i=groupconv_bw(layer, res_i, res_ip1)
    group_index=layer.groupindex;
    [s1,s2,s3,s4]=size(res_i.x);
    res_i.dzdx=gpuArray(single(zeros(s1,s2,s3,s4)));
    res_i.dzdw=cell(1,2);
    res_i.dzdw{1}=gpuArray(single(zeros(size(layer.weights{1}))));      %%%%%%%%%weight belongs to i? ip1?    belongs to i
    res_i.dzdw{2}=gpuArray(single(zeros(size(layer.weights{2}))));
    %res_i.dzdx=gpuArray(single(zeros(size(res_i.x))));
    for i=1:60
        [dzdx, w1, w2] = ...       
          vl_nnconv(res_i.x, layer.weights{1}(group_index(:,i)',:,:,:), layer.weights{2}, res_ip1.dzdx(i,:,:,:), ...
          'pad', 0, ...
          'stride', 1, ...
          layer.opts{:}, ...
          layer.cudnn{:}) ;   
      w1(group_index(:,i)',:,:,:)=w1; 

%      if strcmp(layer.name,'group_conv3')&&i==1
%      disp('w1')
%       w1(:,:,1,1)
%      disp('res_i.dzdx1')
%      dzdx(:,:,1,1)
%      disp('res_i.x')
%       res_i.x(:,:,1,1)
%       
%      end                                                          %still have problem
      res_i.dzdw{1}= res_i.dzdw{1}+w1;
      res_i.dzdw{2}= res_i.dzdw{2}+w2; 
      res_i.dzdx=res_i.dzdx+dzdx;
      clear w1;
      clear w2;
      clear dzdx;                             %%%%still have problems accumulate?
    end
%  if strcmp(layer.name,'group_conv3')
%       disp('weights')
%       layer.weights{1}(:,:,1,1)
%       disp('res_i.dzdw')
%       res_i.dzdw{1}(:,:,1,1) 
%       disp('res_i.dzdx')
%       res_i.dzdx(:,:,1,1)
%       disp('res_ip1.dzdx')
%       res_ip1.dzdx(:,:,1,1)
%     end
    end
    
%     function res_ip1=sub_fx_fw(layer, res_i, res_ip1)
%        if strcmp(layer.method, 'avg')
%            res_ip1.x=mean(mean(res_i.x,1),2);
%        elseif  strcmp(layer.method, 'max')
%            res_ip1.x=max(max(res_i.x,[],1),[],2);
%        else
%             error('Unknown sub_fx method: %s', layer.method);
%        end  
%     
%     end
%     
%  function res_i=sub_fx_bw(layer, res_i, res_ip1)
%        szi=size(res_i.x);
%        if strcmp(layer.method, 'avg')
%            res_i.dzdx=repmat(res_ip1.dzdx,[szi(1),szi(2),1,1])/szi(1)*szi(2);
%        elseif  strcmp(layer.method, 'max')
%            [x,ind1]=max(reshape(res_i.x,[szi(1),szi(2),szi(3)*szi(4)]),[],1);
%            [~,ind]=max(x,[],2);
%            clear x
%            ind11=ind1(sub2ind([1,szi(2),szi(3)*szi(4)],ones(szi(3)*szi(4),1),ind,1:szi(3)*szi(4)));
%            clear ind1
%            Ind=zeros(szi(1),szi(2),szi(3)*szi(4));
%            Ind(sub2ind(size(Ind),ind11,ind,1:szi(3)*szi(4)))=1;
%            res_i.dzdx=repmat(res_ip1.dzdx,[szi(1),szi(2),1,1]).*reshape(Ind,[szi(1),szi(2),szi(3),szi(4)]);
%        else
%             error('Unknown sub_fx method: %s', layer.method);
%        end  
%     end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
