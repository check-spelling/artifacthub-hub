-- updates_repository updates the provided repository in the database.
create or replace function update_repository(p_user_id uuid, p_repository jsonb)
returns void as $$
declare
    v_repository_id uuid;
    v_owner_user_id uuid;
    v_owner_organization_name text;
    v_disabled boolean;
    v_scanner_disabled boolean;
begin
    -- Get some information about the repository
    select repository_id, disabled, scanner_disabled into v_repository_id, v_disabled, v_scanner_disabled
    from repository r
    where r.name = p_repository->>'name'
    for update;

    -- Get user or organization owning the repository
    select r.user_id, o.name into v_owner_user_id, v_owner_organization_name
    from repository r
    left join organization o using (organization_id)
    where r.name = p_repository->>'name';

    -- Check if the user doing the request is the owner or belongs to the
    -- organization which owns it
    if v_owner_organization_name is not null then
        if not user_belongs_to_organization(p_user_id, v_owner_organization_name) then
            raise insufficient_privilege;
        end if;
    elsif v_owner_user_id <> p_user_id then
        raise insufficient_privilege;
    end if;

    -- Update repository
    update repository set
        display_name = nullif(p_repository->>'display_name', ''),
        url = p_repository->>'url',
        branch = nullif(p_repository->>'branch', ''),
        auth_user = nullif(p_repository->>'auth_user', ''),
        auth_pass = nullif(p_repository->>'auth_pass', ''),
        disabled = (p_repository->>'disabled')::boolean,
        scanner_disabled = (p_repository->>'scanner_disabled')::boolean
    where repository_id = v_repository_id;

    -- If the repository has been disabled, remove packages belonging to it
    if (p_repository->>'disabled')::boolean = true and v_disabled = false then
        delete from package where repository_id = v_repository_id;
    end if;

    -- If security scanning has been disabled, remove existing security reports
    if (p_repository->>'scanner_disabled')::boolean = true and v_scanner_disabled = false then
        update snapshot set
            security_report = null,
            security_report_created_at = null,
            security_report_summary = null
        where package_id in (
            select package_id from package where repository_id = v_repository_id
        );
    end if;
end
$$ language plpgsql;
