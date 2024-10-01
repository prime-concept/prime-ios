//
//  Generated code do not edit
//

enum GraphQLConstants {
    static let hotels = """
query Partners($lang: String!, $type: [Int], $q: String, $limit: Int) {
    partners(lang: $lang, type: $type, q: $q, limit: $limit) {
        id
        name
        city {
            id
            name
            country {
                id
                name
            }
        }
        latitude
        longitude
        stars
    }
}

"""
    static let orders = """
query Orders($lang: String!, $taskId: Int, $orderFilter: OrdersSearchFilter) {
    viewer(lang: $lang){
        __typename
            ... on Order {
                orders(taskId: $taskId, filter: $orderFilter) {
                    amount
                    currency
                    description
                    dueDate
                    id
                    initiatorUserId
                    initiatorUserName
                    optionId
                    orderStatus
                    paymentLink
                    paymentUid
                    taskId
                }
        }
    }
}


"""
    static let taskDetails = """
query TaskDetails($lang: String!, $taskId: Int) {
	viewer(lang: $lang){
		__typename
			... on Customer {
			tasks(taskId: $taskId) {
				taskId
				details {
						name
						value
						type
						latitude
						longitude
				}
				responsible {
					lastName
					firstName
					phone
					profileType
				}
			}
		}
	}
}

"""
    static let taskStatistics = """
query TaskStatistics($lang: String!) {
	viewer(lang: $lang){
		__typename
			... on Customer {
			taskStatistics {
				total
				completed
			}
		}
	}
}

"""
    static let partners = """
query Partners($lang: String!, $type: [Int], $q: String, $limit: Int) {
    partners(lang: $lang, type: $type, q: $q, limit: $limit) {
        id
        name
        address
    }
}

"""
    static let countriesWithCities = """
query CountriesWithCities($q: String, $lang: String!) {
    dict {
        countries(q: $q, lang: $lang) {
            id
            name
            cities {
                id
                name
            }
        }
    }
}

"""
    static let citiesWithCountries = """
query CitiesWithCountries($q: String, $lang: String!) {
    dict {
        cities(q: $q, lang: $lang) {
            id
            name
            country {
                id
                name
            }
        }
    }
}

"""
    static let crossSale = """
query CrossSale($lang: String!) {
  viewer {
    ... on Customer {
      taskTypesWithRelated(lang: $lang) {
        id
        name
        related {
          id
          name
        }
      }
    }
  }
}

"""
    static let calendarEvents = """
query CalendarEventsQuery($lang: String!, $year: Int!, $month: Int!) {
    viewer(lang: $lang){
        __typename
            ... on Customer {
            events(month: $month, year: $year) {
                allDay
                backgroundImageUrl
                customerId
                customerName
                description
                endDate
                id
                latitude
                location
                longitude
                startDate
                taskId
                taskInfoId
                taskTypeId
                title
                url
            }
        }
    }
}

"""
    static let create = """
mutation Create($customerId: Int!, $taskRequest: TaskInput!) {
    customer(id: $customerId) {
        task {
            create(input: $taskRequest)
        }
    }
}

"""
    static let countries = """
query Countries($lang: String!) {
    dict {
        countries(lang: $lang) {
            id
            code
            name
        }
    }
}

"""
    static let fetchTaskTypeForm = """
query FetchTaskTypeForm($formId: Int!) {
    taskTypeForm(id: $formId) {
        lang
        field : fields {
            allowBlank
            defaultValue
            hidden
            label
            maxLength
            name
            options {
                name
                value
                visibilityClear
                visibilitySet
            }
            readOnly
            type
            partnerTypeId
            visibility
        }
    }
}

"""
    static let airports = """
query Airports($lang: String!, $lastUpdatedAt: Int!) {
    dict {
        airports(lang: $lang, lastUpdatedAt: $lastUpdatedAt) {
            altCountryName
            altCityName
            isHub
            altName
            city
            code
            country
            deleted
            id
            latitude
            longitude
            name
            updatedAt
            cityId
            vipLoungeCost
        }
    }
}

"""
    static let tasks = """
query Tasks($lang: String!, $limit: Int, $offset: Int, $orderFilter: OrdersSearchFilter, $etag: String, $completed: Boolean, $taskTypeId: Int, $order: TaskOrder) {
    viewer(lang: $lang){
        __typename
            ... on Customer {
            tasks(limit: $limit, offset: $offset, etag: $etag, completed: $completed, taskTypeId: $taskTypeId, order: $order) {
                chatId
                completed
                completedAt
                customerId
                date
                description
                startServiceDate
                endServiceDate
                latitude
                longitude
                id
                optionId
                orders(filter: $orderFilter) {
                    amount
                    currency
                    description
                    dueDate
                    id
                    initiatorUserId
                    initiatorUserName
                    optionId
                    orderStatus
                    paymentLink
                    paymentUid
                    taskId
                }
                requestDate
                reserved
                taskId
                taskType {
                    deleted
                    id
                    name
                }
                title
                taskCloseState
                lastChatMessage {
                    guid
                    clientId
                    channelId
                    source
                    timestamp
                    status
                    type
                    content
                    meta
                }
                responsible {
                    lastName
                    firstName
                    phone
                    profileType
                }
                etag
                deleted
                address
                updatedAt
                unreadCount
            }
        }
    }
}

"""
    static let taskTypes = """
query TaskTypes($lang: String!, $clientId: String) {
    dict {
        taskTypes(lang: $lang, clientId: $clientId) {
            id
            name
            deleted
            groupId
            rowNumber
        }
    }
}

"""
    static let saveTask = """
mutation SaveTask($customerId: Int!, $taskRequest: TaskCreateModifyRequest!) {
    customer(id: $customerId) {
        task {
            saveTask(input: $taskRequest) {
                errors,
                httpCode,
                taskId
            }
        }
    }
}

"""
}