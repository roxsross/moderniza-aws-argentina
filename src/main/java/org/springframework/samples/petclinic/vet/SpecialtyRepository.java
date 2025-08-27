/*
 * Copyright 2012-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.vet;

import org.springframework.dao.DataAccessException;
import org.springframework.data.repository.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;

/**
 * Repository class for <code>Specialty</code> domain objects
 *
 * @author AWS Community Day Argentina 2025
 */
public interface SpecialtyRepository extends Repository<Specialty, Integer> {

	/**
	 * Retrieve all <code>Specialty</code>s from the data store.
	 * @return a <code>Collection</code> of <code>Specialty</code>s
	 */
	@Transactional(readOnly = true)
	Collection<Specialty> findAll() throws DataAccessException;

	/**
	 * Retrieve a <code>Specialty</code> from the data store by id.
	 * @param id the id to search for
	 * @return the <code>Specialty</code> if found
	 * @throws DataAccessException if not found
	 */
	@Transactional(readOnly = true)
	Specialty findById(Integer id) throws DataAccessException;

}
