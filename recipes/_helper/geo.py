from geosupport import Geosupport, GeosupportError
import usaddress
import re

g = Geosupport()


def get_hnum(address):
    address = "" if address is None else address
    result = [k for (k, v) in usaddress.parse(address) if re.search("Address", v)]
    result = " ".join(result)
    fraction = re.findall("\d+[\/]\d+", address)
    if not bool(re.search("\d+[\/]\d+", result)) and len(fraction) != 0:
        result = f"{result} {fraction[0]}"
    return result


def get_sname(address):
    result = (
        [k for (k, v) in usaddress.parse(address) if re.search("Street", v)]
        if address is not None
        else ""
    )
    result = " ".join(result)
    if result == "":
        return address
    else:
        return result


def air_geocode(inputs):

    hnum, sname, borough, street_name_1, street_name_2 = (
        str("" if inputs[k] is None else inputs[k])
        for k in ("hnum", "sname", "borough", "streetname_1", "streetname_2")
    )

    try:
        geo = g["1B"](street_name=sname, house_number=hnum, borough=borough)
        geo = geo_parser(geo)
        geo.update(dict(geo_function="1B"))
    except GeosupportError:
        try:
            geo = g["1B"](
                street_name=sname, house_number=hnum, borough=borough, mode="tpad"
            )
            geo = geo_parser(geo)
            geo.update(dict(geo_function="1B-tpad"))
        except GeosupportError:
            try:
                if street_name_1 != "":
                    geo = g["2"](
                        street_name_1=street_name_1,
                        street_name_2=street_name_2,
                        borough_code=borough,
                    )
                    geo = geo_parser(geo)
                    geo.update(dict(geo_function="Intersection"))
                else:
                    geo = g["1B"](street_name=sname, house_number=hnum, borough=borough)
                    geo = geo_parser(geo)
                    geo.update(dict(geo_function="1B"))
            except GeosupportError as e:
                geo = e.result
                geo = geo_parser(geo)
                geo.update(dict(geo_function=""))

    geo.update(inputs)
    return geo


def geo_parser(geo):
    return dict(
        geo_housenum=geo.get("House Number - Display Format", ""),
        geo_streetname=geo.get("First Street Name Normalized", ""),
        geo_bbl=geo.get("BOROUGH BLOCK LOT (BBL)", {}).get(
            "BOROUGH BLOCK LOT (BBL)", "",
        ),
        geo_bin=geo.get(
            "Building Identification Number (BIN) of Input Address or NAP", ""
        ),
        geo_latitude=geo.get("Latitude", ""),
        geo_longitude=geo.get("Longitude", ""),
        geo_xy_coord=geo.get("Spatial X-Y Coordinates of Address"),
        geo_x_coord=geo.get("SPATIAL COORDINATES", {}).get("X Coordinate", ""),
        geo_y_coord=geo.get("SPATIAL COORDINATES", {}).get("Y Coordinate", ""),
        geo_grc=geo.get("Geosupport Return Code (GRC)", ""),
        geo_grc2=geo.get("Geosupport Return Code 2 (GRC 2)", ""),
        geo_reason_code=geo.get("Reason Code", ""),
        geo_message=geo.get("Message", "msg err"),
    )
