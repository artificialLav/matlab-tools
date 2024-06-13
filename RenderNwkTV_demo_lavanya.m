nwk = nwkHelp.load('/Users/lavanyavaddavalli/Desktop/lppd/data/large_nwk/au.cs31');
RenderNwkTV(nwk,(1:nwk.nf)',nwk.dia,[],[],'test','jet')

capFaces = find(nwk.faceMx(:,1)==110);
notCapFaces = setdiff((1:nwk.nf)',capFaces);

figure
RenderNwkTV(nwk,notCapFaces,nwk.dia,[],[],'test','jet')

figure
RenderNwkTV(nwk,(1:nwk.nf)',nwk.dia,[],nwk.dia,'test','jet')

figure
RenderNwkTV(nwk,(1:nwk.nf)',nwk.dia,[],0.2,'test','jet')

figure
RenderNwkTV(nwk,[find(nwk.faceMx(:,1)==330);find(nwk.faceMx(:,1)==340)],nwk.dia,[],[],'test','jet')

figure
RenderNwkTV(nwk,find(nwk.faceMx(:,1)==330),[],[],[],[],'red')

hold on
RenderNwkTV(nwk,find(nwk.faceMx(:,1)==340),[],[],[],[],'blue')

cmap1 = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1)];
cmap2 = [ones(128,1), linspace(1,0,128)',linspace(1,0,128)'];
cmap = [cmap1;cmap2]; cmap(128,:) = []; %make red to white to blue colormap

C1 = nwkHelp.ConnectivityMx(nwk); C2 = C1'; BC = nwk.BC;
alpha = nwkSim.Resistance(nwk.ptCoordMx, nwk.faceMx, nwk.dia, nwk.nf );
[pp2, ff2, ppAv2, mbError] = nwkSim.solveBloodFlowWithPP(nwk, C1,C2, BC, alpha); %run simulation

figure
RenderNwkTV(nwk,(1:nwk.nf)',[],pp2,[],[],cmap); %pressure as point property
colorbar