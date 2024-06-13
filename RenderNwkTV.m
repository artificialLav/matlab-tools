function [T, p] = RenderNwkTV(nwk,faceSelection,faceProp,pointProp,faceAlpha,figureTitle,cmap)
    %Thomas Ventimiglia 05/15/2024
    %Render network as triangulated tubes
    %If pointProp is nonempty, average point values over faces to obtain faceProp
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %cmap can be a ColorSpec (I.E., 'red', 'blue', 'magenta') specified as a character vector or a string, 
    %cmap can be the name of an official colormap (I.E., 'jet', 'winter', 'hot') specified as a character vector or a string,
    %cmap can be a three column array of RGB values between 0 and 1,
    %If cmap is none of these, then it defaults to [0 0 0], black. 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %If cmap has one row or is a ColorSpec, paint entire network with single color
    %If cmap has more than one row or is an official colormap name, and faceProp is nonempty, then map faceProp to cmap and color network
    %If cmap has more than one row or is an official colormap name, and faceProp is empty, then paint entire network with the first row of cmap
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %If pointProp is nonempty, average point values over faces to obtain face values
    if ~isempty(pointProp)
        faceProp = fillFacesFromPts(pointProp,nwk.nf,nwk.faceMx);
    end
    ptCoordMx = nwk.ptCoordMx; faceMx = nwk.faceMx(faceSelection,:); dia = nwk.dia(faceSelection);
    if isempty(faceMx)
        warning('face selection is empty')
        return
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ax = 2; 
    %Sort faces by diameter
    [dia,ind] = sort(dia); faceMxSorted = faceMx(ind,:);
    %Identify nondegenerate vessels (nonzero length)
    vessels = ptCoordMx(faceMxSorted(:,3),:) - ptCoordMx(faceMxSorted(:,2),:);
    inits = ptCoordMx(faceMxSorted(:,2),:);
    len = vecnorm(vessels,2,2);
    proper = find(len~=0);
    vessels = vessels(proper,:); inits = inits(proper,:); 
    len = len(proper); dia = dia(proper); 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    numres = 5; %Number of resolution levels
    meandia = mean(dia); stddia = std(dia);
    resbreaks = [-Inf,meandia-2*stddia,meandia-stddia,meandia+stddia,meandia+2*stddia,Inf]; %Resolution changes based on diameter histogram
    ppr = (3*2.^(1:numres))'; %points per vessel per resolution
    fpr = ppr; %faces per vessel per resolution
    maxppv = max(ppr); %max number of points in a vessel
    tubes = cell(numres,1); %Columns 1,2, and 3 are x, y, and z coordinates for reference cylinders. cell row is resolution level, from lowest to highest
    faces = cell(numres,1); %reference face matrices
    keeppts = cell(numres,1); %indices of points to keep per resolution (omit padded zeros in point coordinate matrix)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Construct reference tubes and faces
    reslabels = dia;
    %For each resolution level, construct reference cylinder point and face
    %matrices
    for i = 1:numres
        reslabels(resbreaks(i)<dia&dia<=resbreaks(i+1)) = i; %Label vessels according to resolution level
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        keeppts{i} = [true(ppr(i),1); false(maxppv-ppr(i),1)]; %indices of points to keep (non-zero vectors)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cir = 3*2^(i-1);
        [X,Y,Z] = cylinder(ones(ax,1),cir);
        X = X(:,1:end-1); Y = Y(:,1:end-1); Z = Z(:,1:end-1);
        tubes{i} = [[X(:)';Y(:)';Z(:)'],zeros(3,maxppv-ppr(i))]; %Point coordinate matrices of reference tubes are padded with zeros
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        pts = ax*cir;
        v1 = (1:pts)'; v2 = circshift(v1,1); v3 = circshift(v1,1-ax); v6 = circshift(v1,-ax);
        fmx = [v1 v2 v3; v1 v3 v6];
        remove = (1:ax:2*pts)';
        fmx(remove,:) = [];
        faces{i} = fmx; %Face matrix of reference cylinders
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tubes = cell2mat(tubes(reslabels)); faces = cell2mat(faces(reslabels)); %Convert cell to matrix
    keeppts = cell2mat(keeppts(reslabels));
    tubes(3:3:end,:) = tubes(3:3:end,:).*len; %scale z coordinates of reference tubes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    radscale = true(size(tubes,1),1); radscale(3:3:end) = false;
    rad = 0.5*repelem(dia,2,1);
    tubes(radscale,:) = tubes(radscale,:).*rad; %scale x and y coordinates of reference tubes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ppv = ppr(reslabels); %points per vessel
    fpv = fpr(reslabels); %faces per vessel
    faceoffset = [0; cumsum(ppv(1:end-1))]; %Compute offset for face indices
    faceoffset = repelem(faceoffset,fpv,1);
    faces = faces + faceoffset;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Construct block diagonal simultaneous rotation matrix RM
    nf = size(reslabels,1);
    unitvessels = vessels./len;
    B1 = permute(unitvessels(:,1),[3 2 1]);
    B2 = permute(unitvessels(:,2),[3 2 1]);
    B3 = permute(unitvessels(:,3),[3 2 1]);
    zed = zeros(1,1,nf);
    B1sq = B1.^2; B2sq = B2.^2;
    B1B2 = B1.*B2;
    rotscale = (1-B3)./(B1sq+B2sq);
    RM = repmat(eye(3),[1 1 nf]) + [zed zed B1; zed zed B2; -B1 -B2 zed] + rotscale.*[-B1sq -B1B2 zed; -B1B2 -B2sq zed; zed zed -B1sq-B2sq];
    ind1 = ismember(unitvessels,[0 0 -1],'rows');
    ind2 = ismember(unitvessels,[0 0 1],'rows');
    if any(ind1)
        RM(:,:,ind1) = repmat([1 0 0; 0 1 0; 0 0 -1],1,1,nnz(ind1));
    end
    if any(ind2)
        RM(:,:,ind2) = repmat(eye(3),1,1,nnz(ind2));
    end
    vv = RM(:);
    ii = repmat((1:3)',3*nf,1); ii = ii + repelem((0:3:((nf-1)*3))',9,1);
    jj = repelem((1:(3*nf))',3);
    RM = sparse(ii,jj,vv);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rotpts = RM*tubes; %Apply rotation to all tubes simultaneously
    rotpts = mat2cell(rotpts,3*ones(nf,1)); rotpts = rotpts'; rotpts = cell2mat(rotpts); rotpts = rotpts'; %Reshape into point coordinate matrix
    rotpts = rotpts(keeppts,:); %Remove zero padding
    transpts = inits(repelem((1:nf)',ppv),:); 
    pts = transpts + rotpts; %translate rotated tubes into position
    T = triangulation(faces,pts); %Make triangulation from point and face matrices
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Convert given cmap into permissible matrix of RBG values
    if isempty(cmap)
        warning("cmap is empty: using default color")
        cmap = [0 0 0];
    elseif isstring(cmap)||ischar(cmap)
        try
            cmap = validatecolor(cmap);
        catch
            try
                cmap = colormap(cmap);
            catch
                warning("cmap is not a proper ColorSpec or colormap name: using default color")
                cmap = [0 0 0];
            end
        end
    elseif ~isnumeric(cmap)
        warning(strcat("cmap cannot be of type ",class(cmap),": using default color"))
        cmap = [0 0 0];
    elseif size(cmap,2)~=3
        warning("numeric cmap must have three columns: using default color")
        cmap = [0 0 0];
    elseif any(isnan(discretize(cmap,[0 1])),'all')
        warning("numeric cmap must have values between 0 and 1: using default color")
        cmap = [0 0 0];
    end

    %If cmap has one row, paint entire network with single color
    %If cmap has more than one row and faceProp is nonempty, then map faceProp to cmap and color network
    %If cmap has more than one row and faceProp is empty, then paint entire network with the first row of cmap
    if size(cmap,1)==1
        p = plotPatchFromColor(faceAlpha,T,cmap,ind,proper,fpv,figureTitle,faceSelection);
    elseif size(cmap,1)>1
        if ~isempty(faceProp)
            p = plotPatchFromFaces(faceProp,ind,proper,fpv,faceAlpha,T,cmap,figureTitle,faceSelection);
        else
            warning("faceProp is empty: using first row of cmap")
            p = plotPatchFromColor(faceAlpha,T,cmap(1,:),ind,proper,fpv,figureTitle,faceSelection);
        end
    end
end

function faceProp = fillFacesFromPts(pointProp,nf,faceMx)
        np = size(pointProp,1);
        fi = 1:nf;
        p1 = faceMx(:,2)'; p2 = faceMx(:,3)'; % P1IDx   % P2 Idx
        absC1 = sparse(fi, p1, 1,nf,np)+sparse(fi,p2,1,nf,np); % col 1 plus col2 matrices
        faceProp = full(0.5*absC1*pointProp);
end

function p = plotPatchFromFaces(faceProp,ind,proper,fpv,faceAlpha,T,cmap,figureTitle,faceSelection)
    faceProp = faceProp(faceSelection);
    faceProp = faceProp(ind);
    faceProp = faceProp(proper);
    colors = repelem(faceProp,fpv,1);
    if isempty(faceAlpha)
        p = patch('Faces',T.ConnectivityList,'Vertices',T.Points,...
        'FaceVertexCData',colors,...
        'EdgeColor','none','FaceColor','flat');
    elseif length(faceAlpha)==1
        p = patch('Faces',T.ConnectivityList,'Vertices',T.Points,...
        'FaceVertexCData',colors,...
        'EdgeColor','none','FaceColor','flat','FaceAlpha',faceAlpha);
    else
        faceAlpha = faceAlpha(faceSelection);
        faceAlpha = faceAlpha(ind);
        faceAlpha = faceAlpha(proper);
        alphas = repelem(faceAlpha,fpv,1);
        p = patch('Faces',T.ConnectivityList,'Vertices',T.Points,...
        'FaceVertexCData',colors,...
        'EdgeColor','none','FaceColor','flat','FaceVertexAlphaData',alphas,'FaceAlpha','flat');
    end
    colormap(cmap)
    title(figureTitle)
    %daspect([1 1 1])
    view(3)
end

function p = plotPatchFromColor(faceAlpha,T,cmap,ind,proper,fpv,figureTitle,faceSelection)
    if isempty(faceAlpha)
        p = patch('Faces',T.ConnectivityList,'Vertices',T.Points,...
        'EdgeColor','none','FaceColor',cmap);
    elseif length(faceAlpha)==1
        p = patch('Faces',T.ConnectivityList,'Vertices',T.Points,...
        'EdgeColor','none','FaceColor',cmap,'FaceAlpha',faceAlpha);
    else
        faceAlpha = faceAlpha(faceSelection);
        faceAlpha = faceAlpha(ind);
        faceAlpha = faceAlpha(proper);
        alphas = repelem(faceAlpha,fpv,1);
        p = patch('Faces',T.ConnectivityList,'Vertices',T.Points,...
        'EdgeColor','none','FaceColor',cmap,'FaceVertexAlphaData',alphas,'FaceAlpha','flat');
    end
    title(figureTitle)
    %daspect([1 1 1])
    view(3)
end