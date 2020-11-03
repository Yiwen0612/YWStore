--操作员公共调用
use YStore
go
if exists (select * from sysobjects where name='inside_get_handler')
drop proc inside_get_handler
go
create procedure inside_get_handler
@p_hid varchar(8),
@p_erromsg varchar(100) output

as



if not exists (select hid from whandler where hid=@p_hid)
begin
select @p_erromsg='经手人不存在'

return -1
end
else
begin
select @p_erromsg='获取成功'

return 0
end

go

--execute inside_get_handler '001',''