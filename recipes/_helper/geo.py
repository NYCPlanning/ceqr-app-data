from geosupport import Geosupport, GeosupportError
import usaddress
import re

g = Geosupport()

def get_hnum(address):
    """ 
    Parse address to extract house number using usaddress module

    Parameters: 
    address (str): Full address

    Returns:
    result (str): All portions of the address string
                    tagged by usaddress as a house number
    """
    address = "" if address is None else address
    result = [k for (k, v) in usaddress.parse(address) if re.search("Address", v)]
    result = " ".join(result)
    fraction = re.findall("\d+[\/]\d+", address)
    if not bool(re.search("\d+[\/]\d+", result)) and len(fraction) != 0:
        result = f"{result} {fraction[0]}"
    return result


def get_sname(address):
    """ 
    Parse address to extract street name using usaddress module

    Parameters: 
    address (str): Full address

    Returns:
    result (str): All portions of the address string
                    tagged by usaddress as a street name
    """
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

def clean_house(s):
    """ 
    Transform house number to a geosupport-readable format
    
    Replace NULL with empty strings, remove special characters & excess white space,
    take first house number if there is additional information after a / or in parentheses

    Parameters: 
    s (str): House number

    Returns:
    s (str): Cleaned house number
    """
    s = ' ' if s == None else s
    s = re.sub(r"\([^)]*\)", "", s)\
        .replace(' - ', '-')\
        .strip()\
        .split("(",maxsplit=1)[0]\
        .split("/",maxsplit=1)[0]
    return s

def clean_street(s):
    """ 
    Transform street name to a geosupport-readable format
    
    Replace NULL with empty strings, remove apostrophes & special characters,
    take first street name if there is additional information after a / or in parentheses

    Parameters: 
    s (str): Street name

    Returns:
    s (str): Cleaned street name
    """
    s = '' if s == None else s
    s = re.sub(r"\([^)]*\)", "", s)\
        .replace("'","")\
        .split("(",maxsplit=1)[0]\
        .split("/",maxsplit=1)[0]
    return s

def find_stretch(address):
    """ 
    Finds addresses that indicate a stretch and spilts into components

    Parameters: 
    address (str): Full address

    Returns:
    street_1 (str): "On" street
    street_2 (str): Bounding street 1
    street_3 (str): Bounding street 2
    """
    if 'BETWEEN' in address:
        street_1 = address.split('BETWEEN')[0].strip()
        street_2 = (address.split('BETWEEN')[1].split('AND')[0] + address.split(' ')[-1]).strip()
        street_3 = address.split('BETWEEN')[1].split('AND')[1].strip()
        return street_1, street_2, street_3
    else:
        return '','',''
    
def find_intersection(address):
    """ 
    Finds addresses that indicate an intersection and spilts into two streets
    """
    if 'AND' in address:
        street_1 = address.split('AND')[0].strip()
        street_2 = address.split('AND')[1].strip()
        return street_1, street_2
    else:
        return '',''


def air_geocode(inputs):
    """ 
    Runs cleaned & parsed address information through geosupport

    First attempt is 1B, then 1B-TPAD, then 2 

    Parameters: 
    inputs (dict): Contains address information
        including hnum, sname, borough, street_name_1, street_name_2

    Returns:
    geo (dict): Contains inputs as well as geosupport fields
        See geo_parser() for full list of fields
    """
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

class NotIntersection(Exception):
    pass

class NotStretch(Exception):
    pass

def geocode(inputs):
    """ 
    Runs cleaned & parsed address information through geosupport

    First attempt is 1B, then attempts to parse stretch and run 3, then
    attempts to parse intersection and run 2 

    Parameters: 
    inputs (dict): Contains address information
        including hnum, sname, borough, address

    Returns:
    geo (dict): Contains inputs as well as geosupport fields
        See geo_parser() for full list of fields
    """
    hnum = inputs.get('hnum', '')
    sname = inputs.get('sname', '')
    borough = inputs.get('borough', '')

    hnum = str('' if hnum is None else hnum)
    sname = str('' if sname is None else sname)
    borough = str('' if borough is None else borough)
  
    try:
        # First try to geocode using 1B
        geo = g['1B'](street_name=sname, house_number=hnum, borough=borough)
        geo = geo_parser(geo)
        geo.update(geo_function='1B')
    except GeosupportError:
        # Try to parse original address as a stretch
        try:
            street_1, street_2, street_3 = find_stretch(inputs.get('address'))
            if (street_1 != '')&(street_2 != '')&(street_3 != ''):
                # Call to geosupport function 3
                geo = g['3'](street_name_1=street_1, street_name_2=street_2, street_name_3=street_3, borough_code=borough)
                geo_from_node = geo.get('From Node', '')
                geo_to_node = geo.get('To Node', '')
                geo_from_x_coord = g['2'](node=geo_from_node).get('SPATIAL COORDINATES', {}).get('X Coordinate', '')
                geo_from_y_coord = g['2'](node=geo_from_node).get('SPATIAL COORDINATES', {}).get('Y Coordinate', '')
                geo_to_x_coord = g['2'](node=geo_to_node).get('SPATIAL COORDINATES', {}).get('X Coordinate', '')
                geo_to_y_coord = g['2'](node=geo_to_node).get('SPATIAL COORDINATES', {}).get('Y Coordinate', '')
                geo.update(dict(geo_from_x_coord=geo_from_x_coord, geo_from_y_coord=geo_from_y_coord, geo_to_x_coord=geo_to_x_coord, geo_to_y_coord=geo_to_y_coord, geo_function='Segment'))
            else:
                raise NotStretch()
        except (NotStretch, GeosupportError):
            try:
                # Try to parse original address as an intersection
                street_1, street_2 = find_intersection(inputs.get('address'))
                if (street_1 != '')&(street_2 != ''):
                    # Call to geosupport function 2
                    geo = g['2'](street_name_1=street_1, street_name_2=street_2, borough_code=borough)
                    geo = geo_parser(geo)
                    geo.update(dict(geo_function='Intersection'))
                else:
                    raise NotIntersection()
            except (NotIntersection, GeosupportError) as e:
                geo = e.result
                geo = geo_parser(geo)
                geo.update(dict(geo_function=''))

    geo.update(inputs)
    return geo

def geo_parser(geo):
    """ 
    Extracts relevant return fields from geocoding calls

    Parameters: 
    geo (dict): Full return from geosupport

    Returns:
    (dict): Contains geo_housenum, geo_streetname, geo_bbl,
            geo_bin, geo_latitude, geo_longitude, geo_xy_coord,
            geo_x_coord, geo_y_coord, geo_grc, geo_grc2, 
            geo_reason_code, geo_message
    """
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
