setup;
x=zeros(12,1,1,1);
x(1,1,1,1)=1;
x(2,1,1,1)=1;

w=zeros(12,1,1,1);
w(1,1,1,1)=1;
w(2,1,1,1)=1;
w2=zeros(1,1);
a = vl_nnconv(x, w, w2, ...
        'pad', 0, ...
        'stride', 1)