function locf=originalco(level)
a=sqrt(5)/5;
b=2*sqrt(5)/5;
t1=pi/10;
t2=54/180*pi;
x1=[0;0;1];
x2=[0;b;a];
x3=[b*cos(t1);b*sin(t1);a];
x8=[b*cos(-t2);b*sin(-t2);a];
x11=[-b*cos(t2);-b*sin(t2);a];
x7=[-b*cos(t1);b*sin(t1);a];

x5=[0;0;-1];
x4=[b*cos(t1);-b*sin(t1);-a];
x10=-x2;
x12=-x3;
x6=-x8;
x9=-x11;
xlo=[x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12];
xlo=xlo';

if level==1
    locf=xlo;
    return;
end
% figure(1)
% scatter3(xlo(:,1),xlo(:,2),xlo(:,3));
% hold on
% for i=1:12
%     c=num2str(i);
%     c=['',c];
%     text(xlo(i,1),xlo(i,2),xlo(i,3),c);
% end
% 
% [R1,R2]=rotation();
% xlo2=R1*xlo';
% xlo2=xlo2';
% figure(2)
% scatter3(xlo2(:,1),xlo2(:,2),xlo2(:,3));
% hold on
% for i=1:12
%     c=num2str(i);
%     c=['',c];
%     text(xlo2(i,1),xlo2(i,2),xlo2(i,3),c);
% end
% 
% xlo3=R2*xlo';
% xlo3=xlo3';
% figure(3)
% scatter3(xlo3(:,1),xlo3(:,2),xlo3(:,3));
% hold on
% for i=1:12
%     c=num2str(i);
%     c=['',c];
%     text(xlo3(i,1),xlo3(i,2),xlo3(i,3),c);
% end
% 
% 
% xlo4=R1*R2*xlo';
% xlo4=xlo4';
% figure(4)
% scatter3(xlo4(:,1),xlo4(:,2),xlo4(:,3));
% hold on
% for i=1:12
%     c=num2str(i);
%     c=['',c];
%     text(xlo4(i,1),xlo4(i,2),xlo4(i,3),c);
% end
% 



location=cell(20,1);
location{1}=[x1,x2,x3];
location{2}=[x1,x3,x8];
location{3}=[x8,x1,x11];
location{4}=[x2,x3,x9];
location{5}=[x9,x2,x6];
location{6}=[x6,x5,x9];
location{7}=[x5,x12,x6];
location{8}=[x12,x10,x5];
location{9}=[x10,x11,x12];
location{10}=[x11,x10,x8];
location{11}=[x7,x1,x11];
location{12}=[x7,x2,x1];
location{13}=[x7,x6,x2];
location{14}=[x7,x12,x6];
location{15}=[x7,x11,x12];
location{16}=[x4,x8,x10];
location{17}=[x4,x3,x8];
location{18}=[x4,x3,x9];
location{19}=[x4,x9,x5];
location{20}=[x4,x5,x10];

for i=1:level-1
    newlocation=cell(20,4^i);
    for j=1:20
        for k=1:4^(i-1)
            po=location{j,k};
            np1=(po(:,1)+po(:,2))/2;
            np1=np1/norm(np1);
            np2=(po(:,2)+po(:,3))/2;
            np2=np2/norm(np2);
            np3=(po(:,3)+po(:,1))/2;
            np3=np3/norm(np3);
            newlocation{j,4*(k-1)+1}=[po(:,2),np1,np2];
            newlocation{j,4*(k-1)+2}=[po(:,3),np2,np3];
            newlocation{j,4*(k-1)+3}=[po(:,1),np3,np1];
            newlocation{j,4*(k-1)+4}=[np2,np3,np1];
            
        end
    end
    location=newlocation;
end

xnewlo=[];
 for i=1:20
     for j=1:4^(level-1)
         xnewlo=[xnewlo,location{i,j}];
     end
 end
 xnewlo=xnewlo';
 xnewlo=unique(xnewlo,'rows');

 k=0;
index=[];
for i=1:size(xnewlo,1)
   vec=sum(abs(xlo-xnewlo(i,:)),2);
   if ismember(0,vec)
       k=k+1;
       index=[index;[find(vec==0),i]];
       if k==12
           break;
       end   
   end
end

locf=zeros(12,3);
loc42matr=xnewlo;

for i=1:12
   locf(index(i,1),:)=loc42matr(index(i,2),:);
end
xnewlo(index(:,2),:)=[];
locf=[locf;xnewlo];
    
% figure(1)
%  scatter3(locf(:,1),locf(:,2),locf(:,3))
%  hold on
%  for i=1:12
%     c=num2str(i);
%     c=['',c];
%     text(locf(i,1),locf(i,2),locf(i,3),c);
%  end 
%  
 
 
    

% location2=cell(20,4);
% %loc2matr=[];
% for i=1:20
%     po=location{i};
%     np1=(po(:,1)+po(:,2))/2;
%     np1=np1/norm(np1);
%     np2=(po(:,2)+po(:,3))/2;
%     np2=np2/norm(np2);
%     np3=(po(:,3)+po(:,1))/2;
%     np3=np3/norm(np3);
%     location2{i,1}=[po(:,2),np1,np2];
%     location2{i,2}=[po(:,3),np2,np3];
%     location2{i,3}=[po(:,1),np3,np1];
%     location2{i,4}=[np2,np3,np1];
%     %loc2matr=[loc2matr,location2{i,1},location2{i,2},location2{i,3},location2{i,4}];
% end
% % loc2matr=loc2matr';
% % loc2matr=unique(loc2matr,'rows');
% % figure(1)
% % loc2matr=loc2matr';
% % loc2matr=unique(loc2matr,'rows');
% % scatter3(loc2matr(:,1),loc2matr(:,2),loc2matr(:,3))
% 
% location3=cell(20,16);
% %loc3matr=[];
% for i=1:20
%     for j=1:4
%         po=location2{i,j};
%         np1=(po(:,1)+po(:,2))/2;
%         np1=np1/norm(np1);
%         np2=(po(:,2)+po(:,3))/2;
%         np2=np2/norm(np2);
%         np3=(po(:,3)+po(:,1))/2;
%         np3=np3/norm(np3);
%         location3{i,4*(j-1)+1}=[po(:,2),np1,np2];
%         location3{i,4*(j-1)+2}=[po(:,3),np2,np3];
%         location3{i,4*(j-1)+3}=[po(:,1),np3,np1];
%         location3{i,4*(j-1)+4}=[np2,np3,np1];
%         %loc3matr=[loc3matr,location3{i,4*(j-1)+1},location3{i,4*(j-1)+2},location3{i,4*(j-1)+3},location3{i,4*(j-1)+4}];
%     end
% end
% % loc3matr=loc3matr';
% % loc3matr=unique(loc3matr,'rows');
% % figure(2)
% % scatter3(loc3matr(:,1),loc3matr(:,2),loc3matr(:,3))
% % hold on
% % for i=1:12
% %     c=num2str(i);
% %     c=['',c];
% %     text(xlo(i,1),xlo(i,2),xlo(i,3),c);
% % end
% 
% 
% 
% 
% 
% location4=cell(20,64);
% loc4matr=[];
% for i=1:20
%     for j=1:16
%         po=location3{i,j};
%         np1=(po(:,1)+po(:,2))/2;
%         np1=np1/norm(np1);
%         np2=(po(:,2)+po(:,3))/2;
%         np2=np2/norm(np2);
%         np3=(po(:,3)+po(:,1))/2;
%         np3=np3/norm(np3);
%         location4{i,4*(j-1)+1}=[po(:,2),np1,np2];
%         location4{i,4*(j-1)+2}=[po(:,3),np2,np3];
%         location4{i,4*(j-1)+3}=[po(:,1),np3,np1];
%         location4{i,4*(j-1)+4}=[np2,np3,np1];
%         loc4matr=[loc4matr,location4{i,4*(j-1)+1},location4{i,4*(j-1)+2},location4{i,4*(j-1)+3},location4{i,4*(j-1)+4}];
%     end
% end
% loc4matr=loc4matr';
% loc4matr=unique(loc4matr,'rows');
% % figure(3)
% % scatter3(loc4matr(:,1),loc4matr(:,2),loc4matr(:,3))
% % hold on
% % for i=1:12
% %     c=num2str(i);
% %     c=['',c];
% %     text(xlo(i,1),xlo(i,2),xlo(i,3),c);
% % end
% k=0;
% index=[];
% for i=1:size(loc4matr,1)
%    vec=sum(abs(xlo-loc4matr(i,:)),2);
%    if ismember(0,vec)
%        k=k+1;
%        index=[index;[find(vec==0),i]];
%        if k==12
%            break;
%        end   
%    end
% end
% 
%  
% % figure(4)
% % scatter3(loc4matr(:,1),loc4matr(:,2),loc4matr(:,3))
% % hold on
% % for i=1:12
% %     c=num2str(index(i,1));
% %     c=['',c];
% %     ind=index(i,2);
% %     text(loc4matr(ind,1),loc4matr(ind,2),loc4matr(ind,3),c);
% % end
% locf=zeros(12,3);
% loc42matr=loc4matr;
% for i=1:12
%    locf(index(i,1),:)=loc42matr(index(i,2),:);
% end
% loc4matr(index(:,2),:)=[];
% locf=[locf;loc4matr];
% %  figure(5)
% %  scatter3(locf(:,1),locf(:,2),locf(:,3))
% %  hold on
% % for i=1:20
% %     c=num2str(i);
% %     c=['',c];
% %     text(locf(i,1),locf(i,2),locf(i,3),c);
% % end 
% 
% % [R1,R2]=rotation();
% % locf2=R1*locf';
% % locf2=locf2';
% % figure(6)
% % scatter3(locf2(:,1),locf2(:,2),locf2(:,3))
% % hold on
% % for i=1:20
% %     c=num2str(i);
% %     c=['',c];
% %     text(locf2(i,1),locf2(i,2),locf2(i,3),c);
% % end
% 
