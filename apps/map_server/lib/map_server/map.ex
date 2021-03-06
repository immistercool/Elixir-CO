defmodule MapServer.MapSupervisor do
	@moduledoc """
	Manages a specific map. This supervisor splits out a map into
	multiple sectors, which each manage a certain part of the conquer world
	"""

	use Supervisor
	require Logger
	import MapServer.Util.DMap
	import MapServer.Util.SectorUtil
	alias Common.Models.Database.Queries.Portal, as: Portal

	def start_link(map) do
		name = Module.concat(__MODULE__, map.id |> Integer.to_string)
		Supervisor.start_link(__MODULE__, [map], name: name)
	end

	def init([map]) do
		{width, height, dmap} = read_dmap(map.mapdoc)
		portals	= Portal.get_by_map(map.id)
		
		sectors =
		  dmap 
		   |> split_into_sectors(width, height)
		   |> sector_workers(map.id, portals)

		Logger.info "Map #{map.id} width: #{width} height: #{height} sectors: #{sectors |> length}"

		supervise(sectors, strategy: :one_for_one)
	end

	defp sector_workers(sectors, map_id, portals) do
		sectors 
		 |> Enum.map(fn sector -> 
						worker(MapServer.Sector, [map_id, sector.id, sector, portals], [id: sector.id]) 
					end )
	end
end