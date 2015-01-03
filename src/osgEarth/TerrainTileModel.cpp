/* -*-c++-*- */
/* osgEarth - Dynamic map generation toolkit for OpenSceneGraph
* Copyright 2008-2014 Pelican Mapping
* http://osgearth.org
*
* osgEarth is free software; you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>
*/
#include <osgEarth/TerrainTileModel>
#include <osgEarth/ImageLayer>
#include <osgEarth/ImageUtils>
#include <osgEarth/ImageToHeightFieldConverter>
#include <osgEarth/Registry>
#include <osg/Texture2D>

using namespace osgEarth;

#undef  LC
#define LC "[TerrainTileModel] "

namespace
{
    bool layerContainsNewData(const TerrainTileLayerModel* layer) 
    {
        return
            layer != 0L && (
                layer->getMatrix() == 0L ||
                layer->getMatrix()->isIdentity() );
    }

    static osg::ref_ptr<osg::RefMatrixf> s_identityMatrix;
}

//...................................................................

TerrainTileLayerModel::TerrainTileLayerModel()
{
    _matrix = s_identityMatrix.get();
}

//...................................................................

TerrainTileElevationModel::TerrainTileElevationModel() :
_minHeight( FLT_MAX ),
_maxHeight(-FLT_MAX )
{
    //NOP
}

//...................................................................

TerrainTileModel::TerrainTileModel(const TileKey&  key,
                                   const Revision& revision) :
_key     ( key ),
_revision( revision )
{
    //NOP
}

bool
TerrainTileModel::containsNewData() const
{
    for(TerrainTileImageLayerModelVector::const_iterator i = _colorLayers.begin(); i != _colorLayers.end(); ++i)
        if ( layerContainsNewData(i->get()) )
            return true;
    
    for(TerrainTileImageLayerModelVector::const_iterator i = _sharedLayers.begin(); i != _sharedLayers.end(); ++i)
        if ( layerContainsNewData(i->get()) )
            return true;

    if ( layerContainsNewData(_elevationLayer.get()) )
        return true;

    return false;
}

const TerrainTileImageLayerModel*
TerrainTileModel::findSharedLayerByName(const std::string& name) const
{
    for(TerrainTileImageLayerModelVector::const_iterator i = _sharedLayers.begin();
        i != _sharedLayers.end();
        ++i)
    {
        if ( i->get()->getName() == name )
        {
            return i->get();
        }
    }
    return 0L;
}

const TerrainTileImageLayerModel*
TerrainTileModel::findColorLayerByUID(const UID& uid) const
{
    for(TerrainTileImageLayerModelVector::const_iterator i = _colorLayers.begin(); i != _colorLayers.end(); ++i)
    {
        if ( i->get()->getImageLayer() && i->get()->getImageLayer()->getUID() == uid )
        {
            return i->get();
        }
    }
    return 0L;
}