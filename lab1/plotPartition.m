function plotPartition(clusterID)
% plotPartition Plot a road-network partition using different colors.
%
%   plotPartition(clusterID)
%
% INPUT
%   clusterID : N-by-1 vector containing the cluster assignment
%               of each link. The order must correspond to the
%               rows of links.csv.
%
% REQUIRED FILES
%   links.csv
%   nodes.csv
%
% EXAMPLE
%   idx = kmeans(X, 4);
%   plotPartition(idx);

    % ----------------------------------------------------------
    % 1. Locate and read data
    % ----------------------------------------------------------

    % Folder containing this function
    functionFolder = fileparts(mfilename('fullpath'));

    links = readmatrix(fullfile(functionFolder, 'links.csv'));
    nodes = readmatrix(fullfile(functionFolder, 'nodes.csv'));

    % ----------------------------------------------------------
    % 2. Network information
    % ----------------------------------------------------------

    % links.csv:
    % column 1 = Link ID
    % column 4 = Starting node ID
    % column 5 = Ending node ID

    startNode = links(:,4);
    endNode   = links(:,5);

    % nodes.csv:
    % column 1 = Node ID
    % column 2 = x-coordinate
    % column 3 = y-coordinate

    nodeID = nodes(:,1);
    nodeX  = nodes(:,2);
    nodeY  = nodes(:,3);

    % ----------------------------------------------------------
    % 3. Check clusterID
    % ----------------------------------------------------------

    clusterID = clusterID(:);

    nLinks = size(links,1);

    if length(clusterID) ~= nLinks
        error(['clusterID must contain one cluster assignment for ' ...
               'each link in links.csv. Expected %d values, but got %d.'], ...
               nLinks, length(clusterID));
    end

    if any(~isfinite(clusterID))
        error('clusterID contains invalid values.');
    end

    % Unique cluster labels
    clusterLabels = unique(clusterID);
    K = length(clusterLabels);

    % ----------------------------------------------------------
    % 4. Map node IDs to coordinates
    % ----------------------------------------------------------

    [foundStart, startIndex] = ismember(startNode, nodeID);
    [foundEnd, endIndex] = ismember(endNode, nodeID);

    if any(~foundStart)
        error('Some starting nodes in links.csv were not found in nodes.csv.');
    end

    if any(~foundEnd)
        error('Some ending nodes in links.csv were not found in nodes.csv.');
    end

    xStart = nodeX(startIndex);
    yStart = nodeY(startIndex);

    xEnd = nodeX(endIndex);
    yEnd = nodeY(endIndex);

    % ----------------------------------------------------------
    % 5. Plot network partition
    % ----------------------------------------------------------

    figure;
    hold on;

    colors = lines(K);

    legendHandles = gobjects(K,1);

    for k = 1:K

        currentCluster = clusterLabels(k);

        linkMask = (clusterID == currentCluster);

        % NaN separates individual road links so they are not
        % accidentally joined together.
        xPlot = [xStart(linkMask)'; ...
                 xEnd(linkMask)'; ...
                 nan(1,sum(linkMask))];

        yPlot = [yStart(linkMask)'; ...
                 yEnd(linkMask)'; ...
                 nan(1,sum(linkMask))];

        xPlot = xPlot(:);
        yPlot = yPlot(:);

        legendHandles(k) = plot( ...
            xPlot, ...
            yPlot, ...
            'Color', colors(k,:), ...
            'LineWidth', 1.5);

    end

    % ----------------------------------------------------------
    % 6. Figure formatting
    % ----------------------------------------------------------

    axis equal;
    axis off;

    title('Network Partition', ...
        'FontWeight', 'bold');

    legendText = arrayfun( ...
        @(x) sprintf('Cluster %g', x), ...
        clusterLabels, ...
        'UniformOutput', false);

    legend( ...
        legendHandles, ...
        legendText, ...
        'Location', 'bestoutside');

    hold off;

end