/**
 * The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
 * you may not use this file except in compliance with the License. You may obtain a copy of the
 * License at http://www.mozilla.org/MPL/
 *
 * <p>Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
 * ANY KIND, either express or implied. See the License for the specific language governing rights
 * and limitations under the License.
 *
 * <p>The Original Code is OpenELIS code.
 *
 * <p>Copyright (C) The Minnesota Department of Health. All Rights Reserved.
 *
 * <p>Contributor(s): CIRG, University of Washington, Seattle WA.
 */
package org.openelisglobal.typeofsample.daoimpl;

import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.List;
import org.apache.commons.beanutils.PropertyUtils;
import org.hibernate.HibernateException;
import org.hibernate.Session;
import org.hibernate.query.Query;
import org.openelisglobal.common.daoimpl.BaseDAOImpl;
import org.openelisglobal.common.exception.LIMSRuntimeException;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.util.ConfigurationProperties;
import org.openelisglobal.typeofsample.dao.TypeOfSamplePanelDAO;
import org.openelisglobal.typeofsample.valueholder.TypeOfSamplePanel;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component
@Transactional
public class TypeOfSamplePanelDAOImpl extends BaseDAOImpl<TypeOfSamplePanel, String> implements TypeOfSamplePanelDAO {

    private static final Logger logger = LoggerFactory.getLogger(TypeOfSamplePanelDAOImpl.class);

    public TypeOfSamplePanelDAOImpl() {
        super(TypeOfSamplePanel.class);
    }

    @Override
    public List<TypeOfSamplePanel> getAllTypeOfSamplePanels() throws LIMSRuntimeException {
        return List.of();
    }

    @Override
    @Transactional(readOnly = true)
    public List<TypeOfSamplePanel> getPageOfTypeOfSamplePanel(int startingRecNo) throws LIMSRuntimeException {
        List<TypeOfSamplePanel> list;
        try {
            // Validación y manejo de error para pageSize
            String pageSizeStr = ConfigurationProperties.getInstance().getPropertyValue("page.defaultPageSize");
            int pageSize = 10; // Valor por defecto
            try {
                pageSize = pageSizeStr != null && !pageSizeStr.isEmpty() ? Integer.parseInt(pageSizeStr) : pageSize;
            } catch (NumberFormatException e) {
                logger.warn("Error al convertir page.defaultPageSize a entero. Usando valor por defecto: " + pageSize);
            }

            int endingRecNo = startingRecNo + pageSize + 1;

            String sql = "from TypeOfSamplePanel t order by t.typeOfSampleId, t.panelId";
            Query<TypeOfSamplePanel> query = entityManager.unwrap(Session.class).createQuery(sql, TypeOfSamplePanel.class);
            query.setFirstResult(startingRecNo - 1);
            query.setMaxResults(endingRecNo - 1);
            list = query.list();
        } catch (RuntimeException e) {
            logger.error("Error en TypeOfSamplePanel getPageOfTypeOfSamples()", e);
            throw new LIMSRuntimeException("Error en TypeOfSamplePanel getPageOfTypeOfSamples()", e);
        }
        return list;
    }

    @Override
    public void getData(TypeOfSamplePanel typeOfSamplePanel) throws LIMSRuntimeException {

    }

    @Override
    public Integer getTotalTypeOfSamplePanelCount() throws LIMSRuntimeException {
        return 0;
    }

    @Override
    @Transactional(readOnly = true)
    public List<TypeOfSamplePanel> getTypeOfSamplePanelsForSampleType(String sampleType) {
        List<TypeOfSamplePanel> list;
        String sql = "from TypeOfSamplePanel tp where tp.typeOfSampleId = :sampleId order by tp.panelId";
        try {
            int sampleId = 0; // Valor por defecto en caso de error
            try {
                sampleId = sampleType != null && !sampleType.equals("null") && !sampleType.isEmpty()
                        ? Integer.parseInt(sampleType)
                        : sampleId;
            } catch (NumberFormatException e) {
                logger.warn("Error al convertir sampleType a entero. Usando valor por defecto: " + sampleId);
            }

            Query<TypeOfSamplePanel> query = entityManager.unwrap(Session.class).createQuery(sql, TypeOfSamplePanel.class);
            query.setParameter("sampleId", sampleId);
            list = query.list();
        } catch (RuntimeException e) {
            logger.error("Error en getTypeOfSamplePanelsForSampleType", e);
            throw new LIMSRuntimeException("Error en getTypeOfSamplePanelsForSampleType", e);
        }
        return list;
    }

    @Override
    @Transactional(readOnly = true)
    public List<TypeOfSamplePanel> getTypeOfSamplePanelsForPanel(String panelId) throws LIMSRuntimeException {
        List<TypeOfSamplePanel> list = new ArrayList<>();
        String sql = "from TypeOfSamplePanel tosp where tosp.panelId = :panelId";

        try {
            int panelIdInt = 0; // Valor por defecto en caso de error
            try {
                panelIdInt = panelId != null && !panelId.isEmpty() ? Integer.parseInt(panelId) : panelIdInt;
            } catch (NumberFormatException e) {
                logger.warn("Error al convertir panelId a entero. Usando valor por defecto: " + panelIdInt);
            }

            Query<TypeOfSamplePanel> query = entityManager.unwrap(Session.class).createQuery(sql, TypeOfSamplePanel.class);
            query.setParameter("panelId", panelIdInt);
            list = query.list();
        } catch (HibernateException e) {
            handleException(e, "getTypeOfSamplePanelsForPanel");
        }

        return list;
    }
}