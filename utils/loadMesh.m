function [mesh labels labelsmap] = loadMesh(filestr)
% loads a mesh from filestr, supports obj or off

file = fopen( strtrim( filestr ), 'rt');
if file == -1
    warning(['Could not open mesh file: ' filestr]);
    mesh = [];
    return;
end
mesh.filename = strtrim( filestr );

if strcmp( filestr(end-3:end), '.off')
    line = strtrim(fgetl(file));
    skipline = 0;
    if strcmp(line, 'OFF')
        line = strtrim(fgetl(file));
        skipline = 2;
    else
        line = line(4:end);
        skipline = 1;
    end
    [token,line] = strtok(line);
    numverts = eval(token);
    [token,line] = strtok(line);
    numfaces = eval(token);
    mesh.V = zeros( 3, numverts, 'single' );
    mesh.F = zeros( 3, numfaces, 'single' );
    
    DATA = dlmread(filestr, ' ', skipline, 0);
    DATA = DATA(1:numverts+numfaces, :);
    mesh.V(1:3, 1:numverts) = DATA(1:numverts, 1:3)';
    mesh.F(1:3, 1:numfaces) = DATA(numverts+1:numverts+numfaces, 2:4)' + 1;
elseif strcmp( filestr(end-3:end), '.obj')
    mesh.V = zeros(3, 10^6, 'single');
    mesh.Nv = zeros(3, 10^6, 'single');
    mesh.F = zeros(3, 5*10^6, 'uint32');
    v = 0;
    f = 0;
    vn = 0;
    
    while(~feof(file))
        line_type = fscanf(file,'%c',2);
        switch line_type(1)
            case {'#', 'g'}
                fgets(file);
            case 'v'
                if line_type(2) == 'n'
                    vn = vn + 1;
                    normal  = fscanf(file, '%f%f%f');
                    mesh.Nv(:, vn) = normal;
                elseif isspace( line_type(2) )
                    v = v + 1;
                    point = fscanf(file, '%f%f%f');
                    mesh.V(:, v) = point;
                else
                    fgets(file);
                end
            case 'f'
                f = f + 1;
                line=fgetl(file);
                if ~contains(line,'/')
                   ind=strfind(line,' ');
                   on=line(1:ind(1)-1);
                   tw=line(ind(1)+1:ind(2)-1);
                   tr=line(ind(2)+1:end);
                   face=[str2num(on);str2num(tw);str2num(tr)];
                else
                    ind=strfind(line,'/');
                    ind2=strfind(line,' ');
                    if length(ind)==3
                    on=line(1:ind(1)-1);
                    tw=line(ind2(1)+1:ind(2)-1);
                    tr=line(ind2(2)+1:ind(3)-1);
                    face=[str2num(on);str2num(tw);str2num(tr)];
                    elseif length(ind)==6
                    on=line(1:ind(1)-1);
                    tw=line(ind2(1)+1:ind(3)-1);
                    tr=line(ind2(2)+1:ind(5)-1);
                    face=[str2num(on);str2num(tw);str2num(tr)];
                    end
                end
                mesh.F(:, f) = face;
            otherwise
                if feof(file)
                    break;
                end
                if isspace(line_type(1))
                    fseek(file, -1, 'cof');
                    continue;
                end
                fprintf('last string read: %c%c %s', line_type(1), line_type(2), fgets(file));
                fclose(file);
                error('only triangular obj meshes are supported with vertices, normals and faces.');
        end
    end
    mesh.V = mesh.V(:, 1:v);
    mesh.F = mesh.F(:, 1:f);
    mesh.Nv = mesh.Nv(:, 1:v);
end

fclose(file);

end