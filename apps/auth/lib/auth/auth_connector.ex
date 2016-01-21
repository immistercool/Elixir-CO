
defmodule AuthConnector do
	use Reagent.Behaviour
	import Packets
	require Logger

  def handle(conn) do
    case conn |> Socket.Stream.recv! do
      nil ->
        :closed
      data -> 	 
      with {dec, _} 				      = Crypto.decrypt(data, %Crypto{}), 
        	 {:ok, %LoginRequest{}=login} = decode(dec),
        	 {:ok, valid_login}      	  = validate_login(login),
        	 {:ok, server_info}		 	  = get_server(valid_login) do
        		login_response(server_info)
        	 end
       |> handle_result(conn)
    end
  end

  defp handle_result(packet, conn) when is_binary(packet) do
  	{enc, _} = Crypto.encrypt(packet, %Crypto{})
  	conn |> Socket.Stream.send! enc
  end

  defp handle_result(error, conn), do: Logger.debug("Handle eror #{inspect error}")

  defp validate_login(%LoginRequest{username: user, server: server}) do
  	case Auth.Model.Account.get_by_username(user) do
  		[account] -> {:ok, {account.id, server}}
  		[] 		  -> :invalid_login
  	end
  end

  defp get_server({account_id, server}) do
  	case Auth.Model.Servers.get_by_name(server) do
  		[server] -> {:ok, {account_id, 1, server."ServerIP", server."ServerPort"}}
  		[]       -> {:no_server, server}
  	end
  end

end









